import 'dart:math';

class AnomalyResult {
  final bool isAnomalous;
  final double zScore;
  final double mean;
  final double stdDev;
  final String explanation;

  AnomalyResult({
    required this.isAnomalous,
    required this.zScore,
    required this.mean,
    required this.stdDev,
    required this.explanation,
  });
}

class AnomalyDetector {
  bool isAnomalous(double amount, List<double> historicalAmounts) {
    if (historicalAmounts.isEmpty || historicalAmounts.length < 3) {
      return false;
    }

    final stats = _computeStats(historicalAmounts);
    if (stats.$2 == 0) return false;

    final zScore = (amount - stats.$1) / stats.$2;
    return zScore.abs() > 2.0;
  }

  AnomalyResult analyze(double amount, List<double> historicalAmounts) {
    if (historicalAmounts.isEmpty || historicalAmounts.length < 3) {
      return AnomalyResult(
        isAnomalous: false,
        zScore: 0,
        mean: 0,
        stdDev: 0,
        explanation: 'Insufficient transaction history to analyze.',
      );
    }

    final stats = _computeStats(historicalAmounts);
    final mean = stats.$1;
    final stdDev = stats.$2;

    if (stdDev == 0) {
      return AnomalyResult(
        isAnomalous: false,
        zScore: 0,
        mean: mean,
        stdDev: 0,
        explanation: 'All your transactions are the same amount.',
      );
    }

    final zScore = (amount - mean) / stdDev;
    final isAnomalous = zScore.abs() > 2.0;

    String explanation;
    if (zScore > 2.0) {
      final multiplier = (amount / mean).toStringAsFixed(1);
      explanation = 'This ₹${amount.toStringAsFixed(0)} payment is ${multiplier}x your average transaction of ₹${mean.toStringAsFixed(0)}. This is unusual for your spending pattern.';
    } else if (zScore < -2.0) {
      explanation = 'This is unusually small compared to your normal spending.';
    } else {
      explanation = 'This transaction is within your normal spending range.';
    }

    return AnomalyResult(
      isAnomalous: isAnomalous,
      zScore: zScore,
      mean: mean,
      stdDev: stdDev,
      explanation: explanation,
    );
  }

  (double, double) _computeStats(List<double> amounts) {
    if (amounts.isEmpty) return (0, 0);
    
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    
    if (amounts.length == 1) return (mean, 0);
    
    final variance = amounts.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / amounts.length;
    final stdDev = sqrt(variance);
    
    return (mean, stdDev);
  }
}
