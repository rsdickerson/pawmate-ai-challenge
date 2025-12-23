# GraphQL Resolver Pattern for express-graphql + buildSchema

## Issue Discovered During Run 20251223T0849

During the UI implementation run on 2025-12-23, a critical GraphQL resolver structure issue was identified that prevented the API from functioning correctly.

## Problem Description

When using `express-graphql` with `buildSchema` (schema-first approach), there are **two critical requirements**:

### 1. Resolver Structure Must Be Flat

Using nested resolver objects (common in other GraphQL server implementations) causes the following error:

```
GraphQL Error: Cannot return null for non-nullable field Query.listAnimals
```

This error occurs because `buildSchema` + `express-graphql` expects resolvers in this format:

```javascript
{
  getAnimal: (args) => { ... },
  listAnimals: (args) => { ... },
  intakeAnimal: (args) => { ... }
}
```

NOT in this nested format (which is used by Apollo Server and other implementations):

```javascript
{
  Query: {
    getAnimal: (args) => { ... },
    listAnimals: (args) => { ... }
  },
  Mutation: {
    intakeAnimal: (args) => { ... }
  }
}
```

### 2. Resolver Parameter Signature Must Use First Parameter for Args

The resolver function parameters must use the **correct signature**. Arguments are passed in the **first parameter**, not the second:

```javascript
// CORRECT - args in first parameter
listAnimals: ({ status, limit, offset }) => { ... }

// INCORRECT - ignoring first parameter, using second
listAnimals: (_, { status, limit, offset }) => { ... }
```

When the incorrect signature is used, all arguments are `undefined`, causing filters and other parameters to be ignored.

## Root Cause

The `buildSchema` function from the `graphql` package constructs a GraphQL schema from SDL (Schema Definition Language). When combined with `express-graphql`, the `rootValue` option has specific requirements:

1. **Flat resolver structure**: Keys must match operation names defined in the schema (not nested by type)
2. **Parameter signature**: Resolvers receive arguments as `(args, context, info, rootValue)` where `args` is the **first parameter**

This differs from schema-stitching approaches (like Apollo Server's `makeExecutableSchema`) which:
- Expect nested resolvers organized by type (Query, Mutation, etc.)
- Use a different parameter signature: `(parent, args, context, info)`

## Solution

### Option 1: Write Flat Resolvers from the Start (Recommended)

**CRITICAL**: Use the correct parameter signature - arguments are in the **first parameter**:

```javascript
const resolvers = {
  // Queries - destructure args from FIRST parameter
  getAnimal: ({ animalId }) => {
    // animalId comes from the first parameter
    const animal = getAnimalById(animalId);
    return animal;
  },
  
  listAnimals: ({ status, limit = 20, offset = 0 }) => {
    // status, limit, offset come from the first parameter
    // NOT from a second parameter!
    let query = 'SELECT * FROM animals';
    const params = [];
    
    if (status) {  // This will now work correctly
      query += ' WHERE status = ?';
      params.push(status);
    }
    // ... rest of implementation
  },
  
  // Mutations
  intakeAnimal: ({ input }) => {
    // input comes from the first parameter
    const { name, species, description } = input;
    // implementation
  },
  
  transitionAnimalStatus: ({ input }) => {
    // input comes from the first parameter
    const { animalId, fromStatus, toStatus, reason } = input;
    // implementation
  }
};

module.exports = resolvers;
```

**Common mistake** - using `_` to ignore first parameter:
```javascript
// WRONG - This causes all arguments to be undefined!
listAnimals: (_, { status, limit, offset }) => {
  // status, limit, offset are undefined here
  // because buildSchema passes args in the FIRST parameter
}
```

### Option 2: Flatten Nested Resolvers Before Export

If you organize resolvers in nested format during development (for code organization), flatten them before export.

**CRITICAL**: Even when using nested format, you MUST use the correct parameter signature:

```javascript
const resolvers = {
  Query: {
    // CORRECT - args in first parameter
    getAnimal: ({ animalId }) => { /* ... */ },
    listAnimals: ({ status, limit, offset }) => { /* ... */ }
  },
  Mutation: {
    // CORRECT - args in first parameter
    intakeAnimal: ({ input }) => { /* ... */ },
    transitionAnimalStatus: ({ input }) => { /* ... */ }
  }
};

// Flatten for buildSchema compatibility
module.exports = {
  ...resolvers.Query,
  ...resolvers.Mutation
};
```

**Common mistake during refactoring**:
```javascript
// WRONG - Using Apollo Server signature when flattening for buildSchema
const resolvers = {
  Query: {
    listAnimals: (_, { status, limit, offset }) => { /* ... */ }
    //            ^ This underscore is the problem!
  }
};

// Even after flattening, the signature is still wrong:
module.exports = {
  listAnimals: (_, { status, limit, offset }) => { /* ... */ }
  // Args will be undefined because they're in the first parameter, not second
};
```

## Server Configuration

The correct server setup with `express-graphql` and `buildSchema`:

```javascript
const express = require('express');
const { graphqlHTTP } = require('express-graphql');
const { buildSchema } = require('graphql');
const fs = require('fs');
const path = require('path');
const resolvers = require('./resolvers'); // Must be flat!

const app = express();

// Read GraphQL schema
const schemaPath = path.join(__dirname, 'schema.graphql');
const schemaString = fs.readFileSync(schemaPath, 'utf-8');
const schema = buildSchema(schemaString);

// GraphQL endpoint - rootValue must be flat resolvers
app.use('/graphql', graphqlHTTP({
  schema: schema,
  rootValue: resolvers, // Flat resolver object here!
  graphiql: true
}));

app.listen(3000);
```

## Impact on Benchmarking

These issues prevented the GraphQL API from functioning correctly:

1. **Flat resolver structure issue**: Caused "Cannot return null for non-nullable field" errors, preventing any data from being returned
2. **Parameter signature issue**: Caused all arguments to be `undefined`, making filters, pagination, and all parameter-based operations fail silently

### Why These Issues Weren't Caught Earlier

1. The backend server starts successfully (no startup errors)
2. Simple queries without parameters might appear to work
3. GraphQL introspection still works (schema is valid)
4. The errors manifest as:
   - Silent parameter ignoring (filters don't work)
   - Null returns for operations expecting data
   - Operations using all default values instead of provided parameters

### Observable Symptoms

- **Filter by status** in UI shows all animals regardless of selected status
- **Pagination** doesn't respect limit/offset parameters
- **Search** (Model B) ignores search query
- Any operation with parameters behaves as if no parameters were provided

## Prevention for Future Runs

The API start prompt template has been updated (in commit [reference needed]) to include explicit instructions about GraphQL resolver structure when using `express-graphql` with `buildSchema`.

**Section added to prompts/api_start_prompt_template.md:**
- Section 3.0: "CRITICAL — GraphQL Implementation"
- Provides correct and incorrect patterns with examples
- Explains the difference from other GraphQL server implementations

## Testing Recommendations

When implementing GraphQL APIs, verify:

1. ✅ All queries return data (not null) for valid requests
2. ✅ Mutations execute successfully
3. ✅ Error handling returns proper error objects
4. ✅ Test with actual GraphQL client (not just introspection)

## References

- [express-graphql documentation](https://github.com/graphql/express-graphql)
- [graphql-js buildSchema](https://graphql.org/graphql-js/utilities/#buildschema)
- Run 20251223T0849 where this issue was discovered and fixed

## Related Documents

- `prompts/api_start_prompt_template.md` - Updated with GraphQL resolver requirements
- `runs/20251223T0849/PawMate/backend/src/resolvers.js` - Fixed implementation example
- `runs/20251223T0849/PawMate/benchmark/ui_run_summary.md` - Documents the fix during UI integration

---

**Document Version:** 1.0  
**Last Updated:** 2025-12-23  
**Status:** Active guidance for all GraphQL implementations

