namespace 'celdocs'

export[...] {
  functiondef['cel.installdriver'] {
    description = [[Installs a driver for the cel libarary.]];

    synopsis = [==[
      cel.installdriver(mouse, keyboard)
    ]==];

    params = {
      param.table[[mouse - a table that assigns values for the names used by the cel library. 
      A copy of this table is stored and the values can be read through cel.mouse.]];
    };

    returns = {
      param.table[[driver - The interface between the cel libarary and its driver.]]
    };
  };

  notes {
    [[Only one driver is allowed to be installed, installdriver will raise an error after the first call.]];
    [[See cel.driver for a detailed description of the driver interface.]]
  };
}
