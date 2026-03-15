import 'dart:convert';
import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';

class RiskScore {
  final int score;
  final String level;
  final String explanation;
  final String action;
  final List<String> flags;

  RiskScore({
    required this.score,
    required this.level,
    required this.explanation,
    required this.action,
    required this.flags,
  });

  factory RiskScore.defaultScore() {
    return RiskScore(
      score: 50,
      level: 'medium',
      explanation: 'Could not verify at this time. Proceed with caution.',
      action: 'warn',
      flags: ['Verification unavailable'],
    );
  }
}

class GeminiService {
  String? _apiKey;
  final Random _random = Random();

  GeminiService() {
    _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (_apiKey == null || _apiKey!.isEmpty) {
      _apiKey = 'demo_key';
    }
  }

  Future<RiskScore> scorePayment({
    required String recipientUpiId,
    required String recipientName,
    required double amount,
    required double userMonthlyAvg,
    required int recipientAccountAgeDays,
    required int pastTransactionCount,
  }) async {
    if (_apiKey == null || _apiKey == 'demo_key' || _apiKey!.isEmpty) {
      return _generateDemoScore(amount, userMonthlyAvg, recipientAccountAgeDays, pastTransactionCount);
    }

    try {
      final model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey!);
      
      final prompt = '''
Analyze this UPI payment for fraud risk and respond ONLY with JSON in this exact format:
{"score": int, "level": string, "explanation": string, "action": string, "flags": [string]}

Payment details:
- Recipient UPI ID: $recipientUpiId
- Recipient Name: $recipientName
- Amount: ₹$amount
- User's Monthly Average: ₹$userMonthlyAvg
- Recipient Account Age: $recipientAccountAgeDays days
- Past Transactions with Recipient: $pastTransactionCount

Consider:
- New recipients with no history
- Amounts significantly higher than average
- Recently created UPI accounts
- Suspicious UPI ID patterns

Score thresholds: 0-30=low/allow, 31-60=medium/warn, 61-85=high/warn, 86-100=critical/block
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      return _parseJsonResponse(text);
    } catch (e) {
      return _generateDemoScore(amount, userMonthlyAvg, recipientAccountAgeDays, pastTransactionCount);
    }
  }

  Future<RiskScore> scoreUrl(String url) async {
    if (_apiKey == null || _apiKey == 'demo_key' || _apiKey!.isEmpty) {
      return _generateUrlDemoScore(url);
    }

    try {
      final model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey!);
      
      final prompt = '''
Analyze this URL for phishing/malware risk and respond ONLY with JSON:
{"score": int, "level": string, "explanation": string, "action": string, "flags": [string]}

URL: $url

Check for:
- Indian brand impersonation (SBI, HDFC, Paytm, TRAI, CBI, Jio, Airtel)
- Suspicious domain patterns
- Known phishing keywords
- Fake login pages

Score thresholds: 0-30=low/allow, 31-60=medium/warn, 61-85=high/warn, 86-100=critical/block
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      return _parseJsonResponse(text);
    } catch (e) {
      return _generateUrlDemoScore(url);
    }
  }

  Future<RiskScore> scoreRecipient(String upiIdOrPhone) async {
    if (_apiKey == null || _apiKey == 'demo_key' || _apiKey!.isEmpty) {
      return _generateRecipientDemoScore(upiIdOrPhone);
    }

    try {
      final model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey!);
      
      final prompt = '''
Analyze this UPI recipient for fraud risk and respond ONLY with JSON:
{"score": int, "level": string, "explanation": string, "action": string, "flags": [string]}

UPI ID or Phone: $upiIdOrPhone

Check for:
- Unusual or random-looking UPI IDs
- Known fraud patterns
- Community reports indicators

Score thresholds: 0-30=low/allow, 31-60=medium/warn, 61-85=high/warn, 86-100=critical/block
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      return _parseJsonResponse(text);
    } catch (e) {
      return _generateRecipientDemoScore(upiIdOrPhone);
    }
  }

  Future<RiskScore> scoreMessage(String messageText) async {
    if (_apiKey == null || _apiKey == 'demo_key' || _apiKey!.isEmpty) {
      return _generateMessageDemoScore(messageText);
    }
    try {
      final model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey!);
      final prompt = '''
Analyse this SMS/WhatsApp/email message for fraud or scam patterns.
Respond ONLY with JSON in this exact format:
{"score": int, "level": string, "explanation": string, "action": string, "flags": [string]}

Message:
"""
$messageText
"""

Check for these Indian scam patterns:
- OTP/PIN/password sharing requests
- KYC expiry urgency ("account will be blocked")
- Lottery/prize fraud ("you have won")
- Bank/TRAI/CBI/Police impersonation  
- Fake job offers requiring registration fees
- Loan scams charging upfront fees
- Phishing links (bit.ly, shortened URLs)
- Investment fraud with guaranteed returns

Score: 0-30=safe, 31-60=suspicious, 61-85=likely scam, 86-100=definite scam
''';
      final response = await model.generateContent([Content.text(prompt)]);
      return _parseJsonResponse(response.text ?? '');
    } catch (e) {
      return _generateMessageDemoScore(messageText);
    }
  }

  RiskScore _generateMessageDemoScore(String message) {
    final lower = message.toLowerCase();
    int score = 10;
    final List<String> flags = [];

    const criticalKw = ['otp', 'pin', 'password', 'cvv'];
    const highKw = ['kyc', 'blocked', 'suspended', 'verify your account', 'click here', 'arrest', 'cbi', 'police', 'trai', 'prize', 'won', 'lottery', 'winner'];
    const medKw = ['loan', 'investment', 'guaranteed returns', 'work from home', 'earn daily', 'registration fee', 'processing fee'];

    if (criticalKw.any((k) => lower.contains(k))) {
      score += 55;
      flags.add('Requests sensitive credential (OTP/PIN/CVV)');
    }
    if (highKw.any((k) => lower.contains(k))) {
      score += 35;
      flags.add('Contains high-risk scam keywords');
    }
    if (medKw.any((k) => lower.contains(k))) {
      score += 20;
      flags.add('Suspicious financial offer language');
    }
    if (RegExp(r'https?://bit\.ly|tinyurl|t\.co|cutt\.ly').hasMatch(lower)) {
      score += 20;
      flags.add('Contains shortened/suspicious URL');
    }
    if (RegExp(r'\d{10}').hasMatch(message) && lower.contains('call')) {
      score += 10;
      flags.add('Asks you to call an unknown number');
    }

    score = score.clamp(0, 100);

    return RiskScore(
      score: score,
      level: score <= 30 ? 'low' : score <= 60 ? 'medium' : score <= 85 ? 'high' : 'critical',
      explanation: score <= 30 ? 'This message appears safe. No common scam patterns detected.' : score <= 60 ? 'This message has suspicious patterns. Do not click links or share personal info.' : score <= 85 ? 'This is very likely a scam. Delete this message and block the sender immediately.' : 'DEFINITE SCAM. Do not respond, click links, or share anything. Report to 1930.',
      action: score <= 30 ? 'allow' : score <= 60 ? 'warn' : 'block',
      flags: flags,
    );
  }

  RiskScore _parseJsonResponse(String text) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!);
        return RiskScore(
          score: (json['score'] as num?)?.toInt() ?? 50,
          level: json['level'] as String? ?? 'medium',
          explanation: json['explanation'] as String? ?? 'Analysis complete',
          action: json['action'] as String? ?? 'warn',
          flags: (json['flags'] as List<dynamic>?)?.cast<String>() ?? [],
        );
      }
    } catch (e) {
      // Ignore parse errors
    }
    return RiskScore.defaultScore();
  }

  RiskScore _generateDemoScore(double amount, double monthlyAvg, int accountAge, int transactionCount) {
    final amountRatio = amount / monthlyAvg;
    final isNewAccount = accountAge < 30;
    final hasNoHistory = transactionCount == 0;
    
    int score = 20;
    List<String> flags = [];

    if (amountRatio > 5) {
      score += 35;
      flags.add('Amount is ${amountRatio.toStringAsFixed(1)}x your average');
    } else if (amountRatio > 2) {
      score += 15;
      flags.add('Higher than usual amount');
    }

    if (isNewAccount) {
      score += 25;
      flags.add('New UPI account ($accountAge days old)');
    }

    if (hasNoHistory) {
      score += 20;
      flags.add('No prior transaction history');
    }

    if (amount > 10000) {
      score += 10;
      flags.add('Large transaction amount');
    }

    score = score.clamp(0, 100);

    String level;
    String action;
    if (score <= 30) {
      level = 'low';
      action = 'allow';
    } else if (score <= 60) {
      level = 'medium';
      action = 'warn';
    } else if (score <= 85) {
      level = 'high';
      action = 'warn';
    } else {
      level = 'critical';
      action = 'block';
    }

    String explanation;
    if (score <= 30) {
      explanation = 'This payment appears safe. The recipient has a normal transaction profile.';
    } else if (score <= 60) {
      explanation = 'Some risk factors detected. Verify the recipient before proceeding.';
    } else if (score <= 85) {
      explanation = 'Multiple risk factors detected. This payment has been flagged as suspicious.';
    } else {
      explanation = 'High-risk payment detected. Argus Eye recommends blocking this transaction.';
    }

    return RiskScore(
      score: score,
      level: level,
      explanation: explanation,
      action: action,
      flags: flags,
    );
  }

  RiskScore _generateUrlDemoScore(String url) {
    final lowerUrl = url.toLowerCase();
    int score = 15;
    List<String> flags = [];

    final indianBrands = ['sbi', 'hdfc', 'paytm', 'jio', 'airtel', 'trai', 'cbi', 'icici', 'axis'];
    final suspiciousPatterns = ['login', 'verify', 'secure', 'update', 'confirm', 'bank', 'account', 'kyc', 'aadhaar'];
    final suspiciousDomains = ['.xyz', '.top', '.click', '.link', '.work', '.gq', '.ml', '.cf', '.tk', '.pw'];

    bool hasIndianBrand = indianBrands.any((b) => lowerUrl.contains(b));
    bool hasSuspiciousPattern = suspiciousPatterns.any((p) => lowerUrl.contains(p));
    bool hasSuspiciousDomain = suspiciousDomains.any((d) => lowerUrl.contains(d));

    if (hasIndianBrand && hasSuspiciousPattern) {
      score += 45;
      flags.add('Impersonates Indian brand with suspicious URL pattern');
    } else if (hasIndianBrand) {
      score += 20;
      flags.add('Uses Indian brand name - verify authenticity');
    }

    if (hasSuspiciousDomain) {
      score += 30;
      flags.add('Suspicious domain extension');
    }

    if (hasSuspiciousPattern) {
      score += 15;
      flags.add('Contains suspicious URL patterns');
    }

    score = score.clamp(0, 100);

    String level = score <= 30 ? 'low' : score <= 60 ? 'medium' : score <= 85 ? 'high' : 'critical';
    String action = score <= 60 ? 'allow' : 'block';

    return RiskScore(
      score: score,
      level: level,
      explanation: score > 60 
          ? 'This URL has been flagged as potentially dangerous. Do not enter any personal information.'
          : 'This link appears to be safe. However, always verify the URL before sharing personal data.',
      action: action,
      flags: flags,
    );
  }

  RiskScore _generateRecipientDemoScore(String upiId) {
    final lowerId = upiId.toLowerCase();
    int score = 20;
    List<String> flags = [];

    if (lowerId.contains('unknown') || lowerId.contains('test') || lowerId.contains('demo')) {
      score += 30;
      flags.add('Suspicious UPI ID format');
    }

    if (!lowerId.contains('@')) {
      score += 25;
      flags.add('Invalid UPI ID format');
    }

    final suspiciousDomains = ['xyz', 'top', 'click', 'work', 'gq', 'ml', 'cf', 'tk'];
    if (suspiciousDomains.any((d) => lowerId.contains(d))) {
      score += 25;
      flags.add('Non-standard UPI handle');
    }

    score = score.clamp(0, 100);

    return RiskScore(
      score: score,
      level: score <= 30 ? 'low' : score <= 60 ? 'medium' : 'high',
      explanation: score > 50 
          ? 'This recipient has limited transaction history. Exercise caution.' 
          : 'This recipient appears to have a normal profile.',
      action: score <= 60 ? 'allow' : 'warn',
      flags: flags,
    );
  }
}
