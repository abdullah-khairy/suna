import 'package:flutter/material.dart';
import '../../models/service_request_model.dart';
import '../../models/user_model.dart';
import '../../core/utils/external_launcher.dart';
import '../../services/request_service.dart';
import '../auth/auth_dialog.dart';

class ServiceDetailsDialog extends StatefulWidget {
  final ServiceRequestModel request;
  final UserModel? currentUser;
  final Function(UserModel) onLoginRequired;
  final VoidCallback onAccepted;

  const ServiceDetailsDialog({
    super.key,
    required this.request,
    required this.currentUser,
    required this.onLoginRequired,
    required this.onAccepted,
  });

  @override
  State<ServiceDetailsDialog> createState() => _ServiceDetailsDialogState();
}

class _ServiceDetailsDialogState extends State<ServiceDetailsDialog> {
  final RequestService _requestService = RequestService();
  bool _isAccepting = false;
  late ServiceRequestModel _currentRequest;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
  }

  bool get _isAssignedToCurrentUser =>
      widget.currentUser != null &&
      _currentRequest.assignedProviderId == widget.currentUser!.id;

  bool get _isClientOwner =>
      widget.currentUser != null &&
      _currentRequest.clientId == widget.currentUser!.id;

  Future<void> _handleAccept() async {
    if (widget.currentUser == null) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (ctx) => AuthDialog(
          onAuthSuccess: (user) {
            widget.onLoginRequired(user);
          },
        ),
      );
      return;
    }

    setState(() => _isAccepting = true);

    try {
      await _requestService.providerAcceptRequest(
        requestId: _currentRequest.id,
        provider: widget.currentUser!,
      );

      setState(() {
        _currentRequest = _currentRequest.copyWith(
          assignedProviderId: widget.currentUser!.id,
          assignedProviderName: widget.currentUser!.name,
          assignedProviderPhone: widget.currentUser!.phone,
          assignedProviderProfession: widget.currentUser!.profession,
          assignedProviderAge: widget.currentUser!.age,
          assignedProviderRating: widget.currentUser!.rating,
          status: RequestStatus.accepted,
        );
      });

      widget.onAccepted();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('مبروك! تم قبول الطلب بنجاح وظهرت الآن تفاصيل العميل وموقعه.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء قبول الطلب: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAccess = _isAssignedToCurrentUser || _isClientOwner;
    final price = _currentRequest.adminApprovedPrice ?? _currentRequest.suggestedBudget;

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
                  Expanded(
                    child: Text(
                      _currentRequest.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // التصنيف والسعر
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    avatar: const Icon(Icons.category, size: 16),
                    label: Text(_currentRequest.category),
                    backgroundColor: Colors.blue.shade50,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      '$price ريال',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // وصف الخدمة
              const Text('تفاصيل ومواصفات الطلب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _currentRequest.description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),

              // قسم بيانات العميل والموقع (المحمي أو المكشوف)
              if (hasAccess) ...[
                // تم القبول -> إظهار الموقع ورقم الهاتف والأزرار
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isClientOwner ? 'بيانات طلبك' : 'بيانات العميل للتواصل:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('طالب الخدمة: ${_currentRequest.clientName}'),
                      Text('رقم الهاتف: ${_currentRequest.clientPhone}'),
                      if (_currentRequest.addressTitle.isNotEmpty)
                        Text('العنوان: ${_currentRequest.addressTitle}'),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ExternalLauncher.makePhoneCall(_currentRequest.clientPhone);
                              },
                              icon: const Icon(Icons.call, size: 18),
                              label: const Text('اتصال مباشر'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_currentRequest.clientLocation != null)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ExternalLauncher.openGoogleMaps(
                                    latitude: _currentRequest.clientLocation!.latitude,
                                    longitude: _currentRequest.clientLocation!.longitude,
                                  );
                                },
                                icon: const Icon(Icons.directions, size: 18),
                                label: const Text('خرائط جوجل'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade800,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // إذا كان هناك صنايعي تم تعيينه وطالب الخدمة يرى بياناته
                if (_currentRequest.assignedProviderName != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.handyman, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'الصنايعي الذي قبل تقديم الخدمة:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('الاسم: ${_currentRequest.assignedProviderName}'),
                        Text('المهنة: ${_currentRequest.assignedProviderProfession ?? 'مهني متخصص'}'),
                        if (_currentRequest.assignedProviderAge != null)
                          Text('العمر: ${_currentRequest.assignedProviderAge} سنة'),
                        Text('الهاتف: ${_currentRequest.assignedProviderPhone}'),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_currentRequest.assignedProviderPhone != null) {
                              ExternalLauncher.makePhoneCall(_currentRequest.assignedProviderPhone!);
                            }
                          },
                          icon: const Icon(Icons.phone, size: 16),
                          label: const Text('الاتصال بالصنايعي'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade900,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                // لم يتم القبول بعد -> إخفاء البيانات وإظهار زر القبول
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline, color: Colors.amber, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'موقع العميل الدقيق ورقم هاتفه محميان. عند موافقتك على تقديم الخدمة سيتم كشفهما فوراً لتتواصل معه.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _isAccepting ? null : _handleAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isAccepting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'أوافق على تقديم هذه الخدمة',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
