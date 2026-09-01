final Set<String> _swears = {
  // English
  'fuck', 'fucking', 'fucker', 'fucked',
  'cunt', 'cunts',
  'shit', 'shitty', 'bullshit',
  'asshole', 'arsehole',
  'bitch', 'bitches',
  'dicks', 'cock', 'cocks',
  'piss', 'pussy', 'pussies',
  'whore', 'slut', 'bastard',
  'motherfucker', 'motherfuckers', 'motherfucking',
  'twat', 'twats',
  'prick', 'pricks',
  'wanker', 'wankers',
  'bollocks',
  'bugger', 'buggers',
  'cocksucker', 'cocksuckers',
  'dickhead', 'dickheads',
  'asshat', 'asshats',
  'shithead', 'shitheads',
  'fucktard', 'fucktards',
  'pissed',
  'cum', 'jizz',

  // Russian
  'хуй', 'хуя', 'хуи', 'хуёв', 'хуйня',
  'пизда', 'пиздец', 'пизды',
  'ебать', 'ебал', 'ебаный', 'ёбаный', 'ебаная', 'ёбаная',
  'блядь', 'бля', 'бляди',
  'мудак', 'мудила',
  'сука', 'суки',
  'пидор', 'пидорас', 'пидоры',
  'заебал', 'заебала', 'заебали',
  'нахуй', 'похуй',
  'хуйло',
  'hui', 'khuy', 'huy',
  'pizda', 'pizdets', 'pizdec',
  'yebat', 'ebat', 'yobany', 'ebany',
  'blyad', 'blyat', 'blya',
  'mudak',
  'suka',
  'pidor', 'pidoras',
  'zaebal',
  'nahui', 'pohui',

  // Polish
  'kurwa', 'kurwy', 'kurwą',
  'chuj', 'chuja', 'chuje',
  'pizdy',
  'cipa', 'cipy',
  'jebać', 'jebany', 'jebana', 'jebane',
  'pierdolić', 'pierdolony', 'pierdolona',
  'dupa', 'dupy', 'dupek', 'dupki',
  'skurwysyn', 'skurwysyny',
  'gówno', 'gówna', 'gowno',
  'suki',
  'spierdalaj',
};

bool _containsSwear(String value) {
  final normalized = value
      .toLowerCase()
      .replaceAll(RegExp(r"[\s'\-.,]+"), ' ')
      .trim();

  if (normalized.isEmpty) return false;

  final tokens = normalized.split(' ');

  for (final token in tokens) {
    if (_swears.contains(token)) return true;
  }

  for (var i = 0; i < tokens.length - 1; i++) {
    final joined = tokens[i] + tokens[i + 1];
    if (_swears.contains(joined)) return true;
  }

  return false;
}

/// Mirrors whitelist_blacklist_chars.js's
bool isValidGenericField(String value) {
  if (value.isEmpty) return false;

  // Invisible/control/private-use/sinister characters.
  if (RegExp(
    r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u2000-\u200F\u2028-\u202F\u205F-\u206F\u3000\uFEFF\u00AD]',
  ).hasMatch(value)) {
    return false;
  }

  // Zalgo / excessive combining marks.
  if (RegExp(r'\p{M}{5,}', unicode: true).hasMatch(value)) {
    return false;
  }

  // Whitelist: letters, marks, digits, whitespace, and a small set of
  // punctuation. 
  if (!RegExp(r"^[\p{L}\p{M}0-9\s'\-.,]+$", unicode: true).hasMatch(value)) {
    return false;
  }

  if (_containsSwear(value)) {
    return false;
  }

  return true;
}