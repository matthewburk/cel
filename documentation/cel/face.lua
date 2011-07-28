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
  };
};
