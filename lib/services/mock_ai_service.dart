import 'dart:math';
import 'package:tradegasy/models/binance_models.dart';
import 'package:tradegasy/data/market_data_service.dart';
import 'package:tradegasy/services/api_key_manager.dart';

class MockAiService {
  final Random _random = Random();
  final MarketDataService _marketDataService = MarketDataService(
    apiKeyManager: ApiKeyManager(),
  );

  // List of generic market analysis responses for different scenarios (in English)
  final List<String> _bullishResponses = [
    "The chart is showing a strong bullish trend. The price has been consistently making higher highs and higher lows, which is a classic sign of an uptrend. The volume is also increasing during price rises, confirming buyer interest.",

    "I'm seeing a bullish pattern forming. The price has broken above key resistance levels with increasing volume. This suggests strong buying pressure. Consider watching for pullbacks to support levels for potential entry points.",

    "Analysis indicates bullish momentum. The price is trading above major moving averages, and momentum indicators like RSI are showing strength without reaching overbought conditions yet.",

    "The recent price action shows bullish sentiment. After consolidating near support, the price has started moving upward with increased volume. The market structure remains bullish as long as the price stays above the recent swing low.",
  ];

  final List<String> _bearishResponses = [
    "The chart is displaying a bearish trend. We're seeing lower highs and lower lows, which indicates selling pressure. Volume has been increasing on downward movements, suggesting strong seller conviction.",

    "I'm observing bearish price action. The price has broken below important support levels, and selling volume is dominating. This suggests that sellers are in control of the market at the moment.",

    "Analysis shows bearish momentum developing. The price is trading below key moving averages, and momentum indicators are pointing downward. Consider caution if looking for long positions in this environment.",

    "The chart structure appears bearish. After failing to break through resistance, the price has started declining. Watch for any potential breakdown below the current support level.",
  ];

  final List<String> _neutralResponses = [
    "The market is currently in a consolidation phase. Price is moving sideways between support and resistance levels with decreasing volume, suggesting indecision among traders.",

    "I'm seeing a neutral trend on the chart. The price is moving within a range, and neither buyers nor sellers have shown dominance. It might be best to wait for a breakout from this range before making trading decisions.",

    "The analysis shows a balanced market condition. The price is fluctuating around moving averages with no clear direction. Both bullish and bearish scenarios are possible from here.",

    "The chart indicates a period of equilibrium between buyers and sellers. Volume has been declining during this consolidation, which often happens before a significant move. Watch for increases in volume as potential signals for the next trend direction.",
  ];

  final List<String> _generalAdvice = [
    "Remember that all trading carries risk. It's important to use proper risk management techniques like setting stop losses and not risking more than you can afford to lose.",

    "While this analysis provides a perspective on the market, it's always good practice to consider multiple timeframes and indicators before making trading decisions.",

    "Technical analysis should be complemented with fundamental research for a more comprehensive trading approach.",

    "Market conditions can change rapidly. Always monitor your positions and be prepared to adjust your strategy when necessary.",
  ];

  // Specific recommendations for traders based on trend (in English)
  final List<String> _bullishRecommendations = [
    "Next steps for traders: Consider implementing a buy-and-hold strategy with partial profit-taking at key resistance levels. Set trailing stop-losses to protect gains while allowing for continued upside. Look for high-volume breakouts above resistance as potential entry signals for swing trades.",

    "Recommended trader action: Consider buying during pullbacks to key support levels or moving averages. Target the next resistance zone for profit-taking, with a conservative stop-loss below the most recent swing low. Risk no more than 1-2% of your capital on this trade.",

    "Trading strategy recommendation: Look for bullish candlestick patterns like engulfing patterns or morning stars at support levels. Potential profit targets can be set at previous highs or Fibonacci extension levels of 127.2% and 161.8% of the recent range.",

    "For active traders: Consider a pyramiding strategy where you add to your position as the price confirms the uptrend with new higher lows. Set incremental profit targets and raise your stop-loss as the position moves in your favor to secure gains.",
  ];

  final List<String> _bearishRecommendations = [
    "Next steps for traders: Consider staying on the sidelines until signs of trend reversal appear. If already in long positions, tighten stop-losses or hedge with smaller short positions. For short traders, look for bounces to resistance as potential entry points with clear invalidation levels.",

    "Recommended trader action: Exercise caution with any new long positions. Consider waiting for a double bottom pattern or bullish divergence before entering. If trading short, use rallies to key resistance levels as potential entries with strict risk management.",

    "Trading strategy recommendation: Protect capital by reducing position sizes during this bearish phase. Set alert levels at key support zones where you might see a bounce or reversal. Consider options strategies that benefit from increased volatility if available.",

    "For active traders: Look for bearish continuation patterns like flags or pennants to enter short positions. Target previous support levels as potential exit points, and maintain a risk-reward ratio of at least 1:2 for any new trades.",
  ];

  final List<String> _neutralRecommendations = [
    "Next steps for traders: Consider range-bound trading strategies, buying near support and selling near resistance. Set alerts for breakouts in either direction, as these could signal the start of a new trend. Reduce position sizes during consolidation phases.",

    "Recommended trader action: Exercise patience during this consolidation period. Build a watchlist of potential breakout candidates and prepare both bullish and bearish scenarios. Consider using options strategies that benefit from low volatility if available.",

    "Trading strategy recommendation: Look for range compression indicators that might signal an impending breakout. Bollinger Band squeezes or decreasing ATR can help identify potential explosive moves. Prepare orders above resistance and below support to catch the breakout.",

    "For active traders: Consider reduced position sizing during this choppy market phase. Focus on shorter timeframes for scalping opportunities within the range, but be prepared to step aside if volatility becomes too low to generate meaningful returns.",
  ];

  // Liste des réponses bullish en français
  final List<String> _bullishResponsesFr = [
    "Le graphique montre une forte tendance haussière. Le prix a régulièrement établi des sommets et des creux plus élevés, signe classique d'une tendance à la hausse. Le volume augmente également lors des hausses de prix, confirmant l'intérêt des acheteurs.",

    "Je vois la formation d'un pattern haussier. Le prix a franchi des niveaux de résistance clés avec un volume croissant. Cela suggère une forte pression d'achat. Surveillez les replis vers les niveaux de support pour d'éventuels points d'entrée.",

    "L'analyse indique un momentum haussier. Le prix évolue au-dessus des principales moyennes mobiles, et les indicateurs de momentum comme le RSI montrent de la force sans atteindre encore des conditions de surachat.",

    "L'action récente des prix montre un sentiment haussier. Après s'être consolidé près du support, le prix a commencé à monter avec un volume accru. La structure du marché reste haussière tant que le prix reste au-dessus du récent plus bas.",
  ];

  // Liste des réponses baissières en français
  final List<String> _bearishResponsesFr = [
    "Le graphique affiche une tendance baissière. Nous observons des sommets et des creux plus bas, ce qui indique une pression de vente. Le volume a augmenté sur les mouvements à la baisse, suggérant une forte conviction des vendeurs.",

    "J'observe une action de prix baissière. Le prix a cassé sous des niveaux de support importants, et le volume de vente domine. Cela suggère que les vendeurs contrôlent actuellement le marché.",

    "L'analyse montre un momentum baissier en développement. Le prix évolue sous les moyennes mobiles clés, et les indicateurs de momentum pointent vers le bas. Faites preuve de prudence si vous recherchez des positions longues dans cet environnement.",

    "La structure du graphique semble baissière. Après avoir échoué à franchir la résistance, le prix a commencé à baisser. Surveillez toute rupture potentielle sous le niveau de support actuel.",
  ];

  // Liste des réponses neutres en français
  final List<String> _neutralResponsesFr = [
    "Le marché est actuellement dans une phase de consolidation. Le prix évolue latéralement entre les niveaux de support et de résistance avec un volume décroissant, suggérant une indécision parmi les traders.",

    "Je vois une tendance neutre sur le graphique. Le prix évolue dans une fourchette, et ni les acheteurs ni les vendeurs n'ont montré de dominance. Il pourrait être préférable d'attendre une sortie de cette fourchette avant de prendre des décisions de trading.",

    "L'analyse montre une condition de marché équilibrée. Le prix fluctue autour des moyennes mobiles sans direction claire. Des scénarios tant haussiers que baissiers sont possibles à partir d'ici.",

    "Le graphique indique une période d'équilibre entre acheteurs et vendeurs. Le volume a diminué pendant cette consolidation, ce qui arrive souvent avant un mouvement significatif. Surveillez les augmentations de volume comme signaux potentiels pour la prochaine direction de tendance.",
  ];

  // Conseils généraux en français
  final List<String> _generalAdviceFr = [
    "Rappelez-vous que tout trading comporte des risques. Il est important d'utiliser des techniques de gestion du risque appropriées comme la mise en place de stops loss et ne pas risquer plus que ce que vous pouvez vous permettre de perdre.",

    "Bien que cette analyse fournisse une perspective sur le marché, c'est toujours une bonne pratique de considérer plusieurs timeframes et indicateurs avant de prendre des décisions de trading.",

    "L'analyse technique devrait être complétée par une recherche fondamentale pour une approche de trading plus complète.",

    "Les conditions de marché peuvent changer rapidement. Surveillez toujours vos positions et soyez prêt à ajuster votre stratégie si nécessaire.",
  ];

  // Recommandations spécifiques pour les traders basées sur la tendance en français
  final List<String> _bullishRecommendationsFr = [
    "Prochaines étapes pour les traders : Envisagez de mettre en œuvre une stratégie d'achat et de conservation avec prise partielle de bénéfices aux niveaux de résistance clés. Mettez en place des stops loss suiveurs pour protéger les gains tout en permettant une hausse continue. Recherchez des cassures à fort volume au-dessus de la résistance comme signaux d'entrée potentiels pour des trades de swing.",

    "Action recommandée pour le trader : Envisagez d'acheter lors des replis vers les niveaux de support clés ou les moyennes mobiles. Visez la prochaine zone de résistance pour prendre des bénéfices, avec un stop loss conservateur sous le plus récent plus bas de swing. Ne risquez pas plus de 1-2% de votre capital sur ce trade.",

    "Recommandation de stratégie de trading : Recherchez des patterns de chandeliers haussiers comme des figures d'engloutissement ou des étoiles du matin aux niveaux de support. Les objectifs de profit potentiels peuvent être fixés aux précédents sommets ou aux niveaux d'extension de Fibonacci de 127,2% et 161,8% de la fourchette récente.",

    "Pour les traders actifs : Envisagez une stratégie de pyramiding où vous ajoutez à votre position à mesure que le prix confirme la tendance haussière avec de nouveaux creux plus élevés. Fixez des objectifs de profit progressifs et relevez votre stop loss à mesure que la position évolue en votre faveur pour sécuriser les gains.",
  ];

  final List<String> _bearishRecommendationsFr = [
    "Prochaines étapes pour les traders : Envisagez de rester sur la touche jusqu'à ce que des signes de renversement de tendance apparaissent. Si vous êtes déjà en positions longues, resserrez les stops loss ou couvrez avec de plus petites positions courtes. Pour les traders en short, recherchez des rebonds vers la résistance comme points d'entrée potentiels avec des niveaux d'invalidation clairs.",

    "Action recommandée pour le trader : Faites preuve de prudence avec toute nouvelle position longue. Envisagez d'attendre un pattern de double fond ou une divergence haussière avant d'entrer. Si vous tradez à la baisse, utilisez les rallyes vers les niveaux de résistance clés comme entrées potentielles avec une gestion stricte du risque.",

    "Recommandation de stratégie de trading : Protégez le capital en réduisant les tailles de position pendant cette phase baissière. Définissez des niveaux d'alerte aux zones de support clés où vous pourriez voir un rebond ou un renversement. Envisagez des stratégies d'options qui bénéficient d'une volatilité accrue si disponible.",

    "Pour les traders actifs : Recherchez des patterns de continuation baissière comme des drapeaux ou des fanions pour entrer en positions courtes. Visez les niveaux de support précédents comme points de sortie potentiels, et maintenez un ratio risque-récompense d'au moins 1:2 pour tout nouveau trade.",
  ];

  final List<String> _neutralRecommendationsFr = [
    "Prochaines étapes pour les traders : Envisagez des stratégies de trading en fourchette, achetant près du support et vendant près de la résistance. Définissez des alertes pour les cassures dans les deux directions, car celles-ci pourraient signaler le début d'une nouvelle tendance. Réduisez les tailles de position pendant les phases de consolidation.",

    "Action recommandée pour le trader : Faites preuve de patience pendant cette période de consolidation. Constituez une liste de surveillance de candidats potentiels à la cassure et préparez des scénarios tant haussiers que baissiers. Envisagez d'utiliser des stratégies d'options qui bénéficient d'une faible volatilité si disponible.",

    "Recommandation de stratégie de trading : Recherchez des indicateurs de compression de fourchette qui pourraient signaler une cassure imminente. Les compressions de bandes de Bollinger ou la diminution de l'ATR peuvent aider à identifier des mouvements explosifs potentiels. Préparez des ordres au-dessus de la résistance et en dessous du support pour attraper la cassure.",

    "Pour les traders actifs : Envisagez de réduire la taille des positions pendant cette phase de marché instable. Concentrez-vous sur des timeframes plus courts pour des opportunités de scalping au sein de la fourchette, mais soyez prêt à vous mettre de côté si la volatilité devient trop faible pour générer des rendements significatifs.",
  ];

  // Generate a mock market analysis based on candle data
  Future<String> generateMarketAnalysis({
    required String symbol,
    required String interval,
    required List<Candle> candles,
    required String question,
    String? locale, // Ajout du paramètre de langue
  }) async {
    // Get technical analysis data with numerical indicators
    Map<String, dynamic> technicalData = await _marketDataService
        .getTechnicalAnalysisData(candles, symbol, interval);

    String trend = technicalData['trend'] as String;

    // Déterminer la langue à utiliser
    bool useFrench = locale != null && locale.startsWith('fr');

    // Select appropriate responses based on trend and language
    List<String> trendResponses;
    List<String> trendRecommendations;
    List<String> adviceList;

    if (useFrench) {
      // Utiliser les réponses en français
      adviceList = _generalAdviceFr;

      switch (trend) {
        case 'bullish':
          trendResponses = _bullishResponsesFr;
          trendRecommendations = _bullishRecommendationsFr;
          break;
        case 'bearish':
          trendResponses = _bearishResponsesFr;
          trendRecommendations = _bearishRecommendationsFr;
          break;
        default:
          trendResponses = _neutralResponsesFr;
          trendRecommendations = _neutralRecommendationsFr;
      }
    } else {
      // Utiliser les réponses en anglais
      adviceList = _generalAdvice;

      switch (trend) {
        case 'bullish':
          trendResponses = _bullishResponses;
          trendRecommendations = _bullishRecommendations;
          break;
        case 'bearish':
          trendResponses = _bearishResponses;
          trendRecommendations = _bearishRecommendations;
          break;
        default:
          trendResponses = _neutralResponses;
          trendRecommendations = _neutralRecommendations;
      }
    }

    // Generate a response
    String mainResponse =
        trendResponses[_random.nextInt(trendResponses.length)];
    String advice = adviceList[_random.nextInt(adviceList.length)];
    String recommendation =
        trendRecommendations[_random.nextInt(trendRecommendations.length)];

    // Get numerical data to include in the response
    var indicators = technicalData['indicators'];
    double currentPrice = technicalData['currentPrice'] as double;
    String rsi = indicators['rsi'] as String;
    String sma20 = indicators['sma20'] as String;
    String sma50 = indicators['sma50'] as String;
    String priceChange = indicators['priceChange'] as String;
    var macd = indicators['macd'];
    var volume = indicators['volume'];
    var levels = indicators['levels'];

    // Create a numerical summary section
    String numericalSummary;
    if (useFrench) {
      numericalSummary = """
1. Prix actuel: ${currentPrice.toStringAsFixed(2)}
2. Variation sur 10 jours: ${priceChange}%
3. RSI (14): ${rsi}
4. SMA 20: ${sma20}
5. SMA 50: ${sma50}
6. MACD: ${macd['line']} (Signal: ${macd['signal']})
7. Volume: Actuel ${volume['current']}, Moyenne sur 7 jours ${volume['average']} (variation de ${volume['change']})
8. Niveaux clés: Support à ${levels['support']}, Résistance à ${levels['resistance']}
""";
    } else {
      numericalSummary = """
1. Current Price: ${currentPrice.toStringAsFixed(2)}
2. 10-Day Price Change: ${priceChange}%
3. RSI (14): ${rsi}
4. SMA 20: ${sma20}
5. SMA 50: ${sma50}
6. MACD: ${macd['line']} (Signal: ${macd['signal']})
7. Volume: Current ${volume['current']}, 7-day avg ${volume['average']} (${volume['change']} change)
8. Key Levels: Support at ${levels['support']}, Resistance at ${levels['resistance']}
""";
    }

    // Add specific details about the question
    String questionResponse = _generateQuestionResponse(
      question,
      trend,
      candles,
      technicalData,
      useFrench,
    );

    // Format the final response with numerical data
    if (useFrench) {
      return """Basé sur l'analyse du graphique $symbol en $interval:

$mainResponse

$numericalSummary

Concernant votre question: $questionResponse

$recommendation

$advice

Note: Cette analyse est générée localement sur votre appareil et est fournie à des fins éducatives uniquement.
""";
    } else {
      return """Based on the $symbol $interval chart analysis:

$mainResponse

$numericalSummary

Regarding your question: $questionResponse

$recommendation

$advice

Note: This analysis is generated locally on your device and is meant for educational purposes only.
""";
    }
  }

  // Determine the trend from candle data
  String _determineTrend(List<Candle> candles) {
    if (candles.isEmpty || candles.length < 2) {
      return 'neutral';
    }

    // Simple trend determination based on first and last candle
    Candle firstCandle = candles.first;
    Candle lastCandle = candles.last;

    double priceChange = lastCandle.close - firstCandle.open;
    double percentChange = (priceChange / firstCandle.open) * 100;

    if (percentChange > 3) {
      return 'bullish';
    } else if (percentChange < -3) {
      return 'bearish';
    } else {
      return 'neutral';
    }
  }

  // Generate a response specific to the question with numerical data
  String _generateQuestionResponse(
    String question,
    String trend,
    List<Candle> candles,
    Map<String, dynamic> technicalData,
    bool useFrench,
  ) {
    // Extract keywords from the question
    question = question.toLowerCase();

    var indicators = technicalData['indicators'];
    var levels = indicators['levels'];
    String rsi = indicators['rsi'];

    // Check for specific question types and include numerical data
    if (question.contains('entry') ||
        question.contains('buy') ||
        question.contains('long')) {
      return _generateEntryResponse(trend, candles, technicalData, useFrench);
    } else if (question.contains('exit') ||
        question.contains('sell') ||
        question.contains('short')) {
      return _generateExitResponse(trend, candles, technicalData, useFrench);
    } else if (question.contains('support') ||
        question.contains('resistance')) {
      return "Based on the recent price action, key support appears to be around ${levels['support']}, and key resistance can be observed around ${levels['resistance']}. Watch these levels for potential bounces or breakouts.";
    } else if (question.contains('volume') || question.contains('liquidity')) {
      return _generateVolumeResponse(candles, technicalData, useFrench);
    } else {
      // Generic response for other questions with numerical data
      return "Based on the current $trend trend with RSI at $rsi, you should consider the overall market direction and structure before making any trading decisions. Current support is near ${levels['support']} and resistance is at ${levels['resistance']}. Always use proper risk management techniques.";
    }
  }

  String _generateEntryResponse(
    String trend,
    List<Candle> candles,
    Map<String, dynamic> technicalData,
    bool useFrench,
  ) {
    var indicators = technicalData['indicators'];
    var levels = indicators['levels'];
    String support = levels['support'];
    String rsi = indicators['rsi'];

    if (useFrench) {
      // Réponse en français avec encodage correct des accents
      if (trend == 'bullish') {
        return "Avec la tendance haussière actuelle et un RSI à $rsi, les points d'entrée potentiels pourraient se situer lors des replis vers les niveaux de support autour de $support. Attendez une confirmation comme un rebond ou une figure de chandelier haussière avant d'entrer.";
      } else if (trend == 'bearish') {
        return "Dans cette tendance baissière avec un RSI à $rsi, prendre des positions longues comporte un risque plus élevé. Si vous envisagez une position longue, il serait préférable d'attendre des signes de renversement de tendance ou que le prix teste le support à $support.";
      } else {
        return "Le marché est actuellement dans une condition de range avec un RSI à $rsi. Envisagez des entrées près des niveaux de support autour de $support avec des stops losses sous les récents plus bas. Attendez une confirmation de cassure avant de prendre des positions plus importantes.";
      }
    } else {
      // English responses remain unchanged
      if (trend == 'bullish') {
        return "With the current bullish trend and RSI at $rsi, potential entry points could be during pullbacks to support levels near $support. Wait for confirmation like a bounce or a bullish candlestick pattern before entering.";
      } else if (trend == 'bearish') {
        return "In this bearish trend with RSI at $rsi, entering long positions carries higher risk. If you're considering a long position, it might be better to wait for signs of trend reversal or until price tests support at $support.";
      } else {
        return "The market is currently in a range-bound condition with RSI at $rsi. Consider entries near support levels around $support with stop losses below recent lows. Wait for a breakout confirmation before taking larger positions.";
      }
    }
  }

  String _generateExitResponse(
    String trend,
    List<Candle> candles,
    Map<String, dynamic> technicalData,
    bool useFrench,
  ) {
    var indicators = technicalData['indicators'];
    var levels = indicators['levels'];
    String resistance = levels['resistance'];
    String support = levels['support'];

    if (useFrench) {
      // Réponses en français avec encodage correct des accents
      if (trend == 'bullish') {
        return "Dans une tendance haussière, envisagez d'utiliser des stops suiveurs pour maximiser le potentiel de profit tout en protégeant les gains. Surveillez la résistance près de $resistance, et soyez prudent si le RSI atteint des conditions de surachat au-dessus de 70.";
      } else if (trend == 'bearish') {
        return "Si vous avez des positions longues dans ce marché baissier, envisagez de resserrer les stops loss ou de prendre des bénéfices partiels. Pour les positions courtes, recherchez les rebonds potentiels depuis le support près de $support pour prendre des bénéfices.";
      } else {
        return "Avec le marché en consolidation, envisagez de prendre des bénéfices lorsque le prix s'approche de la limite supérieure de la fourchette de consolidation près de $resistance. Définissez des niveaux de prise de bénéfice clairs basés sur la fourchette établie.";
      }
    } else {
      // English responses
      if (trend == 'bullish') {
        return "In a bullish trend, consider using trailing stops to maximize profit potential while protecting gains. Watch for resistance near $resistance, and be cautious if RSI reaches overbought conditions above 70.";
      } else if (trend == 'bearish') {
        return "If you have long positions in this bearish market, consider tightening stop losses or taking partial profits. For short positions, look for potential bounces from support near $support to take profit.";
      } else {
        return "With the market in consolidation, consider taking profits as price approaches the upper range of the consolidation pattern near $resistance. Set clear take-profit levels based on the established range.";
      }
    }
  }

  String _generateVolumeResponse(
    List<Candle> candles,
    Map<String, dynamic> technicalData,
    bool useFrench,
  ) {
    var indicators = technicalData['indicators'];
    var volume = indicators['volume'];
    int currentVolume = volume['current'];
    int avgVolume = volume['average'];
    String volumeChange = volume['change'];

    if (useFrench) {
      // Réponses en français avec encodage correct des accents
      if (volumeChange.startsWith('-')) {
        return "Le volume a récemment diminué à $currentVolume par rapport à la moyenne sur 7 jours de $avgVolume ($volumeChange), ce qui arrive souvent pendant les phases de consolidation. Surveillez l'expansion du volume car elle précède souvent les cassures ou les ruptures de prix.";
      } else if (double.parse(volumeChange.replaceAll('%', '')) > 50) {
        return "Le volume récent est significativement plus élevé que la moyenne ($currentVolume contre $avgVolume, augmentation de $volumeChange), suggérant un fort intérêt aux niveaux de prix actuels. Cela pourrait indiquer une accélération potentielle de la tendance actuelle ou un point de renversement possible.";
      } else {
        return "Le volume semble cohérent avec les niveaux moyens récents ($currentVolume contre $avgVolume, variation de $volumeChange). Pour que les mouvements de prix significatifs soient validés, recherchez les augmentations correspondantes en volume.";
      }
    } else {
      // English responses
      if (volumeChange.startsWith('-')) {
        return "Volume has been declining recently to $currentVolume from 7-day average of $avgVolume ($volumeChange), which often happens during consolidation phases. Watch for volume expansion as it often precedes price breakouts or breakdowns.";
      } else if (double.parse(volumeChange.replaceAll('%', '')) > 50) {
        return "Recent volume is significantly higher than the average ($currentVolume vs $avgVolume, $volumeChange increase), suggesting strong interest at current price levels. This could indicate a potential acceleration of the current trend or a possible reversal point.";
      } else {
        return "Volume appears to be consistent with recent average levels ($currentVolume vs $avgVolume, $volumeChange change). For significant price moves to be validated, look for corresponding increases in volume.";
      }
    }
  }
}
