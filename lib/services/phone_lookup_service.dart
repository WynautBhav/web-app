class PhoneLookupService {
  static final Map<String, Map<String, String>> _mockDatabase = {};

  static Future<Map<String, String>?> lookupPhone(String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanNumber.length < 10) return null;
    
    final last10 = cleanNumber.length > 10 ? cleanNumber.substring(cleanNumber.length - 10) : cleanNumber;
    
    if (_mockDatabase.containsKey(last10)) {
      return _mockDatabase[last10];
    }

    final names = [
      'Rahul Sharma', 'Priya Patel', 'Amit Kumar', 'Sneha Reddy',
      'Vikram Singh', 'Anjali Gupta', 'Raj Malhotra', 'Kavita Joshi',
      'Sanjay Verma', 'Meera Krishnan', 'Arun Nair', 'Pooja Shah',
    ];
    
    final banks = [
      'State Bank of India', 'HDFC Bank', 'ICICI Bank', 'Axis Bank',
      'Bank of Baroda', 'Punjab National Bank', 'Canara Bank', 'Yes Bank',
    ];
    
    // Use a deterministic seed from the phone number so the same number always returns the same name
    final seed = last10.split('').map(int.parse).fold(0, (a, b) => a + b);
    final name = names[seed % names.length];
    final bank = banks[(seed * 3) % banks.length];
    final upiHandles = ['upi', 'sbi', 'hdfc', 'icici'];
    final upiId = '${name.toLowerCase().replaceAll(' ', '')}@${upiHandles[(seed * 7) % upiHandles.length]}';
    
    final result = {
      'name': name,
      'phone': '+91 $last10',
      'upiId': upiId,
      'bank': bank,
      'accountVerified': 'Verified',
      'riskLevel': _calculateRisk(last10),
    };
    
    _mockDatabase[last10] = result;
    return result;
  }
  
  static String _calculateRisk(String number) {
    final sum = number.split('').map((e) => int.parse(e)).fold(0, (a, b) => a + b);
    if (sum < 20) return 'Low';
    if (sum < 35) return 'Medium';
    return 'High';
  }
}
