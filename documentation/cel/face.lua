export {
  typedef['face'] {
    [[A face is a table context for the renderer to store information that it needs to render a cel.]];
    [[The contents of a face are dictated by the renderer, but Cel reserves these entries:]];
    list {
      key.font[[if present this should be a font returned from cel.loadfont()]];
      key.layout[[if present this should be a table describing the layout of the cel, 
                  each metacel will define its own layout if any.]];
      key.flow[[if present this should be a table of flow functions, the metacel will define the names
                to use and what they mean.]];
    };

    functiondef['face:new([t])'] {
      [[Creates a new face that inherits all the properties of the existing face.]];
      [[Inheritance is via metatable.__index, not copying.]];

      code[=[
      cel.getface('cel'):new {
        a = 'a',
        b = 'b', 
      }
      ]=];

      params = {
        param.table[[t - optional table to use to create the new face.  If this is nil a table is created for
        the new face.]];
      };

      returns = {
        param.face[[a new face that inherits the properties of this face.]];
      };
    };

    functiondef['face:register(name)'] {
      [[Give the specified name to the face so that it may be looked up by name.]];
      [[The name must be unique to the metacel face.  For example 2 faces could be registered with the same name as
      long as they are for different metacels.  To lookup the face use cel.getface(metacelname, name) where name
      is the name passed to face:register()]];

      code[=[
      cel.getface('cel'):new {
        a = 'a',
        b = 'b', 
      }:register('@ab')

      cel.getface('button'):new {
        a = 'A',
        b = 'B', 
      }:register('@ab')

      assert(cel.getface('cel', '@ab').a == 'a')
      assert(cel.getface('button', '@ab').a == 'A')
      ]=];

      params = {
        param.any[[name - name of the face, typically a string.]];
      };

      returns = {
        param.face[[self.]];
      };
    };
  };
};
