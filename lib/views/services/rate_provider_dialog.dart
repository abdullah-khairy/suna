import 'package:flutter/material.dart';
import '../../models/service_request_model.dart';
import '../../services/request_service.dart';

class RateProviderDialog extends StatefulWidget {
  final ServiceRequestModel request;
  final VoidCallback onRated;

  const RateProviderDialog({super.key, required this.request, required this.onRated});

  @override
  State<RateProviderDialog> createState() => _RateProviderDialogState();
}

class _RateProviderDialogState extends State<RateProviderDialog> {
  final RequestService _requestService = RequestService();
  final TextEditingController _reviewController = TextEditingController();

  double _selectedRating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String _getRatingText(double rating) {
    if (rating >= 5.0) return 'ممتاز جداً 🌟🌟🌟🌟🌟';
    if (rating >= 4.0) return 'جيد جداً 👍';
    if (rating >= 3.0) return 'جيد 👌';
    if (rating >= 2.0) return 'مقبول 😐';
    return 'ضعيف / غير راضٍ 👎';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.amber.shade800;
    if (rating >= 3.0) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  Future<void> _submitRating() async {
    final providerId = widget.request.assignedProviderId;
    if (providerId == null || providerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم يتم تحديد فني لهذا الطلب!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final price = widget.request.finalPrice ?? widget.request.adminApprovedPrice ?? widget.request.suggestedBudget;

      await _requestService.clientConfirmAndRateService(requestId: widget.request.id, providerId: providerId, ratingStars: _selectedRating, review: _reviewController.text.trim(), finalPrice: price);

      if (mounted) {
        Navigator.pop(context, true);
        widget.onRated();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شكراً لك! تم تأكيد إتمام الخدمة وتقييم الفني بنجاح ⭐'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerName = widget.request.assignedProviderName ?? 'المغامر';
    final profession = widget.request.assignedProviderProfession ?? 'مهني';
    final price = widget.request.finalPrice ?? widget.request.adminApprovedPrice ?? widget.request.suggestedBudget;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // العنوان وإغلاق
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('تأكيد تمام الخدمة وتقييم الفني', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // كرت مختصر لبيانات الفني والخدمة
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.blue.shade900,
                      child: const Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(providerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('المهنة: $profession  |  الخدمة: ${widget.request.title}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                    Text(
                      '${price.toStringAsFixed(0)} ${widget.request.effectiveCurrency}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green.shade800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // رسالة السؤال
              const Center(
                child: Text('كيف كانت تجربتك مع الفني؟', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text('تقييمك يساعد المغامرة المتميزين ويضمن جودة العمل', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              const SizedBox(height: 14),

              // محدد النجوم التفاعلي (1 إلى 5)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1.0;
                  final isFilled = starValue <= _selectedRating;

                  return IconButton(
                    iconSize: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    icon: Icon(isFilled ? Icons.star_rounded : Icons.star_outline_rounded, color: isFilled ? Colors.amber.shade700 : Colors.grey.shade400),
                    onPressed: () {
                      setState(() => _selectedRating = starValue);
                    },
                  );
                }),
              ),
              const SizedBox(height: 4),

              // نص التقييم الحالي
              Center(
                child: Text(
                  _getRatingText(_selectedRating),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _getRatingColor(_selectedRating)),
                ),
              ),
              const SizedBox(height: 16),

              // حقل التعليق الاختياري
              TextField(
                controller: _reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'رأيك أو تعليقك على أداء الفني (اختياري)',
                  hintText: 'اكتب كلمة شكر أو ملاحظاتك حول سرعة وإتقان العمل...',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.rate_review_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // زر التأكيد والتقييم
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitRating,
                icon: _isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle, size: 20),
                label: Text(_isSubmitting ? 'جاري الاعتماد...' : 'تأكيد تمام الخدمة وإرسال التقييم ✅', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
