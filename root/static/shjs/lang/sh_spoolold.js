if (! this.sh_languages) {
  this.sh_languages = {};
}
sh_languages['spool'] = [
  [
    [
      /\b(?:VARCHAR|VARBINARY)\b/gi,
      'sh_type',
      -1
    ],
    [
      /\b(?:ALLOCATED|ADD|STEP)\b/gi,
      'sh_keyword',
      -1
    ],
    [ /IEB\w+/g, 'sh_keyword', -1 ],
    [ /\/\*/g, 'sh_string', 4 ],
    [ /\/\//g, 'sh_string', 4 ],
    [ /\/\*\*/g, 'sh_string', 4 ],
    [ /\/\*/g, 'sh_comment', 4 ],
    [ /XX\*/g, 'sh_comment', 4 ],
    [ /XX/g, 'sh_string', 4 ],
    [
      /~|!|%|\^|\*|\(|\)|-|\+|=|\[|\]|\\|:|;|,|\.|\/|\?|&|<|>|\|/g,
      'sh_symbol',
      -1
    ],
    [
      /\b[+-]?(?:(?:0x[A-Fa-f0-9]+)|(?:(?:[\d]*\.)?[\d]+(?:[eE][+-]?[\d]+)?))u?(?:(?:int(?:8|16|32|64))|L)?\b/g,
      'sh_number',
      -1
    ]
  ],
  [
    [ /"/g, 'sh_string', -2 ],
    [ /\\./g, 'sh_specialchar', -1 ]
  ],
  [
    [ /`/g, 'sh_string', -2 ],
    [ /\\./g, 'sh_specialchar', -1 ]
  ],
  [
    [ /$/g, null, -2 ]
  ],
  [
    [ /$/g, null, -2 ],
    [ /(?:<?)[A-Za-z0-9_\.\/\-_~]+@[A-Za-z0-9_\.\/\-_~]+(?:>?)|(?:<?)[A-Za-z0-9_]+:\/\/[A-Za-z0-9_\.\/\-_~]+(?:>?)/g, 'sh_url', -1 ],
    [ /<(?:\/)?[A-Za-z](?:[A-Za-z0-9_:.-]*)(?:\/)?>/g, 'sh_keyword', -1 ],
    [ /<(?:\/)?[A-Za-z](?:[A-Za-z0-9_:.-]*)/g, 'sh_keyword', 10, 1 ],
    [ /<(?:\/)?[A-Za-z][A-Za-z0-9]*(?:\/)?>/g, 'sh_keyword', -1 ],
    [ /<(?:\/)?[A-Za-z][A-Za-z0-9]*/g, 'sh_keyword', 10, 1 ],
    [ /(?:RC)(?:[:]?)/g, 'sh_todo', -1 ],
    [ /@[A-Za-z]+/g, 'sh_type', -1 ]
  ],
  [
    [ /\?>/g, 'sh_preproc', -2 ],
    [ /([^=" \t>]+)([ \t]*)(=?)/g, ['sh_type', 'sh_normal', 'sh_symbol'],
      -1
    ],
    [ /"/g, 'sh_string', 7 ]
  ],
  [
    [ /\\(?:\\|")/g, null, -1 ],
    [ /"/g, 'sh_string', -2 ]
  ],
  [
    [ />/g, 'sh_preproc', -2 ],
    [ /([^=" \t>]+)([ \t]*)(=?)/g, ['sh_type', 'sh_normal', 'sh_symbol'], -1 ],
    [ /"/g, 'sh_string', 7 ]
  ],
  [
    [ /-->/g, 'sh_comment', -2 ],
    [ /<!--/g, 'sh_comment', 9 ]
  ],
  [
    [ /(?:\/)?>/g, 'sh_keyword', -2 ],
    [ /([^=" \t>]+)([ \t]*)(=?)/g, ['sh_type', 'sh_normal', 'sh_symbol'], -1 ],
    [ /"/g, 'sh_string', 7 ]
  ],
  [
    [ /\*\//g, 'sh_comment', -2 ],
    [ /(?:<?)[A-Za-z0-9_\.\/\-_~]+@[A-Za-z0-9_\.\/\-_~]+(?:>?)|(?:<?)[A-Za-z0-9_]+:\/\/[A-Za-z0-9_\.\/\-_~]+(?:>?)/g, 'sh_url', -1 ],
    [ /<\?xml/g, 'sh_preproc', 6, 1 ],
    [
      /<!DOCTYPE/g,
      'sh_preproc',
      8,
      1
    ],
    [
      /<(?:\/)?[A-Za-z](?:[A-Za-z0-9_:.-]*)(?:\/)?>/g,
      'sh_keyword',
      -1
    ],
    [
      /<(?:\/)?[A-Za-z](?:[A-Za-z0-9_:.-]*)/g,
      'sh_keyword',
      10,
      1
    ],
    [
      /<(?:\/)?[A-Za-z][A-Za-z0-9]*(?:\/)?>/g,
      'sh_keyword',
      -1
    ],
    [
      /<(?:\/)?[A-Za-z][A-Za-z0-9]*/g,
      'sh_keyword',
      10,
      1
    ],
    [
      /@[A-Za-z]+/g,
      'sh_type',
      -1
    ]
  ],
  [
    [ /\*\//g, 'sh_comment', -2 ],
    [ /(?:<?)[A-Za-z0-9_\.\/\-_~]+@[A-Za-z0-9_\.\/\-_~]+(?:>?)|(?:<?)[A-Za-z0-9_]+:\/\/[A-Za-z0-9_\.\/\-_~]+(?:>?)/g, 'sh_url', -1 ],
    [ /(?:TODO|FIXME|BUG)(?:[:]?)/g, 'sh_todo', -1 ]
  ]
];
