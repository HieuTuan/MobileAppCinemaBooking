import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../api/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';

class WithdrawalFormScreen extends StatefulWidget {
  const WithdrawalFormScreen({
    super.key,
    required this.userId,
    required this.maxAmount,
  });

  final String userId;
  final int maxAmount;

  @override
  State<WithdrawalFormScreen> createState() => _WithdrawalFormScreenState();
}

class _WithdrawalFormScreenState extends State<WithdrawalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accNumberCtrl = TextEditingController();
  final _accHolderCtrl = TextEditingController();

  _BankOption? _selectedBank;
  bool _submitted = false;
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _bankNameCtrl.dispose();
    _accNumberCtrl.dispose();
    _accHolderCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    final amountText = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(amountText) ?? 0;

    setState(() => _submitting = true);

    try {
      await APIClient().requestWithdrawal(
        widget.userId,
        amount,
        _bankNameCtrl.text.trim(),
        _accNumberCtrl.text.trim(),
        _accHolderCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Gửi yêu cầu rút tiền thành công'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      _showError('Lỗi: ${e.toString()}');
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _selectBank() async {
    final bank = await showModalBottomSheet<_BankOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _BankPickerSheet(),
    );

    if (bank == null) return;
    setState(() {
      _selectedBank = bank;
      _bankNameCtrl.text = '${bank.code} - ${bank.name}';
    });
    _formKey.currentState?.validate();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateAmount(String? value) {
    final amountText = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (amountText.isEmpty) return 'Vui lòng nhập số tiền';

    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) return 'Số tiền không hợp lệ';
    if (amount < 10000) return 'Số tiền rút tối thiểu là 10,000 VND';
    if (amount > widget.maxAmount) {
      return 'Số tiền không được vượt quá ${money(widget.maxAmount)}';
    }
    return null;
  }

  String? _validateAccountNumber(String? value) {
    final accountNumber = value?.trim() ?? '';
    if (accountNumber.isEmpty) return 'Vui lòng nhập số tài khoản';
    if (accountNumber.length < 6) return 'Số tài khoản phải có ít nhất 6 số';
    if (accountNumber.length > 19) return 'Số tài khoản tối đa 19 số';
    return null;
  }

  String? _validateAccountHolder(String? value) {
    final holder = value?.trim() ?? '';
    if (holder.isEmpty) return 'Vui lòng nhập tên chủ TK';
    if (holder.length < 4) return 'Tên chủ tài khoản quá ngắn';
    if (!RegExp(r'^[A-Z]+(?: [A-Z]+)*$').hasMatch(holder)) {
      return 'Chỉ dùng chữ không dấu, in hoa và khoảng trắng';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Rút tiền về tài khoản',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Số dư khả dụng: ${money(widget.maxAmount)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDeco(
                  'Số tiền cần rút (VND)',
                  Icons.money_rounded,
                ),
                validator: _validateAmount,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bankNameCtrl,
                readOnly: true,
                onTap: _selectBank,
                decoration: _bankInputDeco(),
                validator: (_) =>
                    _selectedBank == null ? 'Vui lòng chọn ngân hàng' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _accNumberCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(19),
                ],
                decoration: _inputDeco('Số tài khoản', Icons.numbers_rounded),
                validator: _validateAccountNumber,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _accHolderCtrl,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [_AccountHolderFormatter()],
                decoration: _inputDeco(
                  'Tên chủ tài khoản',
                  Icons.person_rounded,
                ),
                validator: _validateAccountHolder,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'XÁC NHẬN YÊU CẦU',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _bankInputDeco() {
    final bank = _selectedBank;
    return _inputDeco('Chọn ngân hàng', Icons.account_balance_rounded).copyWith(
      prefixIcon: bank == null
          ? const Icon(Icons.account_balance_rounded, color: AppColors.muted)
          : Padding(
              padding: const EdgeInsets.all(10),
              child: _BankLogo(bank: bank, compact: true),
            ),
      suffixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.muted),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorMaxLines: 2,
    );
  }
}

class _BankPickerSheet extends StatefulWidget {
  const _BankPickerSheet();

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<_BankOption> _results = _banks;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String value) {
    setState(() {
      _results = _banks.where((bank) => _matchesBank(bank, value)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .82,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chọn ngân hàng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: 'Đóng',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc mã ngân hàng',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      onPressed: () {
                        _searchCtrl.clear();
                        _search('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
            ),
            onChanged: _search,
          ),
          const SizedBox(height: 12),
          Flexible(
            child: _results.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Không tìm thấy ngân hàng phù hợp',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.line),
                    itemBuilder: (context, index) {
                      final bank = _results[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _BankLogo(bank: bank),
                        title: Text(
                          bank.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(bank.code),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.pop(context, bank),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BankLogo extends StatelessWidget {
  const _BankLogo({required this.bank, this.compact = false});

  final _BankOption bank;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 44.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bank.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            bank.code,
            maxLines: 1,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountHolderFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = _removeVietnameseMarks(newValue.text)
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');

    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }
}

class _BankOption {
  const _BankOption({
    required this.code,
    required this.name,
    required this.color,
    this.aliases = const [],
  });

  final String code;
  final String name;
  final Color color;
  final List<String> aliases;

  String get searchText => [code, name, ...aliases].join(' ');
}

const _banks = [
  _BankOption(
    code: 'VCB',
    name: 'Vietcombank',
    color: Color(0xFF007A3D),
    aliases: ['Ngoại thương Việt Nam', 'Viet Cong Thuong', 'Vietcom'],
  ),
  _BankOption(
    code: 'BIDV',
    name: 'BIDV',
    color: Color(0xFF006B68),
    aliases: ['Đầu tư và Phát triển Việt Nam'],
  ),
  _BankOption(
    code: 'CTG',
    name: 'VietinBank',
    color: Color(0xFF005BAC),
    aliases: ['Công Thương Việt Nam'],
  ),
  _BankOption(
    code: 'TCB',
    name: 'Techcombank',
    color: Color(0xFFE30613),
    aliases: ['Kỹ thương Việt Nam', 'Techcom'],
  ),
  _BankOption(
    code: 'MB',
    name: 'MB Bank',
    color: Color(0xFF102B6A),
    aliases: ['MBBank', 'Quân đội'],
  ),
  _BankOption(
    code: 'ACB',
    name: 'ACB',
    color: Color(0xFF0055A4),
    aliases: ['Á Châu'],
  ),
  _BankOption(
    code: 'VPB',
    name: 'VPBank',
    color: Color(0xFF009A44),
    aliases: ['Việt Nam Thịnh Vượng'],
  ),
  _BankOption(
    code: 'VIB',
    name: 'VIB',
    color: Color(0xFFF58220),
    aliases: ['Quốc tế Việt Nam'],
  ),
  _BankOption(
    code: 'TPB',
    name: 'TPBank',
    color: Color(0xFF5B2C83),
    aliases: ['Tiên Phong'],
  ),
  _BankOption(
    code: 'STB',
    name: 'Sacombank',
    color: Color(0xFF003C7E),
    aliases: ['Sài Gòn Thương Tín'],
  ),
  _BankOption(
    code: 'HDB',
    name: 'HDBank',
    color: Color(0xFFE31B23),
    aliases: ['Phát triển TP HCM'],
  ),
  _BankOption(
    code: 'SHB',
    name: 'SHB',
    color: Color(0xFFF37021),
    aliases: ['Sài Gòn Hà Nội'],
  ),
  _BankOption(
    code: 'MSB',
    name: 'MSB',
    color: Color(0xFFE30613),
    aliases: ['Hàng Hải Việt Nam', 'Maritime Bank'],
  ),
  _BankOption(
    code: 'OCB',
    name: 'OCB',
    color: Color(0xFF00A651),
    aliases: ['Phương Đông'],
  ),
  _BankOption(
    code: 'EIB',
    name: 'Eximbank',
    color: Color(0xFF005BAB),
    aliases: ['Xuất Nhập Khẩu Việt Nam'],
  ),
  _BankOption(
    code: 'SSB',
    name: 'SeABank',
    color: Color(0xFFD71920),
    aliases: ['Đông Nam Á'],
  ),
  _BankOption(
    code: 'LPB',
    name: 'LPBank',
    color: Color(0xFFB5121B),
    aliases: ['Bưu điện Liên Việt', 'LienVietPostBank'],
  ),
  _BankOption(
    code: 'NAB',
    name: 'Nam A Bank',
    color: Color(0xFF0072BC),
    aliases: ['Nam Á'],
  ),
  _BankOption(
    code: 'ABB',
    name: 'ABBank',
    color: Color(0xFF00ADEF),
    aliases: ['An Bình'],
  ),
  _BankOption(
    code: 'AGR',
    name: 'Agribank',
    color: Color(0xFF8B1E41),
    aliases: ['Nông nghiệp và Phát triển Nông thôn'],
  ),
];

bool _matchesBank(_BankOption bank, String query) {
  final normalizedQuery = _normalizeSearch(query);
  if (normalizedQuery.isEmpty) return true;

  final haystack = _normalizeSearch(bank.searchText);
  if (haystack.contains(normalizedQuery)) return true;

  final words = normalizedQuery.split(' ').where((word) => word.isNotEmpty);
  if (words.every(haystack.contains)) return true;

  return _isSubsequence(
    normalizedQuery.replaceAll(' ', ''),
    haystack.replaceAll(' ', ''),
  );
}

bool _isSubsequence(String query, String text) {
  if (query.isEmpty) return true;
  var queryIndex = 0;
  for (final unit in text.codeUnits) {
    if (unit == query.codeUnitAt(queryIndex)) {
      queryIndex++;
      if (queryIndex == query.length) return true;
    }
  }
  return false;
}

String _normalizeSearch(String value) {
  return _removeVietnameseMarks(
    value,
  ).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

String _removeVietnameseMarks(String value) {
  const from =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
      'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
  const to =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
      'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';

  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    final index = from.indexOf(char);
    buffer.write(index == -1 ? char : to[index]);
  }
  return buffer.toString();
}
