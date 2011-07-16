template['T.function']
{
  description = [[Returns true if the mouse pointer is in a cel and not in any links of the cel.]];

  synopsis = [==[ 
    acel:hasmousefocus()
  ]==];

  params = {
    [[cel self - self]];
  };

  returns = {
    [[boolean focus - true if the mouse pointer is in self and not in any links of self.]];
  };

  notes = {
    [[TODO there is no method analogous to hasfocus for keyboard, this will be confusing]];
    [[When a cel has the mouse focus it will recieve mouse events. The events will also be sent to each host of
      the cel in order from the cel to the cel.root, if a cel has trapped the mouse then mouse events will not
      be sent to any hosts of that cel]];
  };
}
