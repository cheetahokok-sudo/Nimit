/// Trending symbol banner data (e.g. "นกขาว" +38% today).
class TrendingSymbol {
  const TrendingSymbol({
    required this.nameTh,
    required this.changePercent,
    required this.noteTh,
  });

  final String nameTh;
  final int changePercent;
  final String noteTh;
}

/// How often a number is being mentioned (for the bar chart).
class NumberMention {
  const NumberMention({required this.number, required this.count});

  final String number;
  final int count;
}

class CommunityStory {
  const CommunityStory({required this.quoteTh});

  final String quoteTh;
}

class TrendsData {
  const TrendsData({
    required this.hotSymbol,
    required this.mentions,
    required this.story,
  });

  final TrendingSymbol hotSymbol;
  final List<NumberMention> mentions;
  final CommunityStory story;
}
