if (! this.sh_languages) {
  this.sh_languages = {};
}
sh_languages['spool'] = [
  [
    [ /IEB\w+/g, 'sh_keyword', -1 ],
    [ /\/\*/g, 'sh_string', 1 ],
    [ /\/\//g, 'sh_string', 1 ],
    [ /\/\*\*/g, 'sh_string', 1 ],
    [ /\/\*/g, 'sh_comment', 1 ],
    [ /XX\*/g, 'sh_comment', 1 ],
    [ /XX/g, 'sh_string', 1 ],
    [ /RC=/g, 'sh_specialchar', 1 ],
    [ /\]\]/g, 'sh_specialchar', 1 ],
    [
      /\b[+-]?(?:(?:0x[A-Fa-f0-9]+)|(?:(?:[\d]*\.)?[\d]+(?:[eE][+-]?[\d]+)?))u?(?:(?:int(?:8|16|32|64))|L)?\b/g,
      'sh_number',
      -1
    ]
  ],
  [
    [ /$/g, null, -2 ]
  ]
];
