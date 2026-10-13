import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/supplier_model.dart';
import '../core/services/location_service.dart';

class SupplierService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _suppliersCollection => _firestore.collection('suppliers');

  /// إضافة مورد أو محل جديد
  Future<SupplierModel> addSupplier(SupplierModel supplier) async {
    final docRef = supplier.id.isEmpty ? _suppliersCollection.doc() : _suppliersCollection.doc(supplier.id);

    final newSupplier = supplier.id.isEmpty ? supplier.copyWith(id: docRef.id) : supplier;
    await docRef.set(newSupplier.toMap(), SetOptions(merge: true));
    return newSupplier;
  }

  /// متابعة جميع الموردين والمحلات (مع إمكانية الفلترة حسب القسم)
  Stream<List<SupplierModel>> streamSuppliers({String? category, String? searchQuery}) {
    Query query = _suppliersCollection;
    if (category != null && category.isNotEmpty && category != 'الكل') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      var list = snapshot.docs.map((doc) => SupplierModel.fromFirestore(doc)).toList();
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        list = list.where((s) => s.name.toLowerCase().contains(q) || s.description.toLowerCase().contains(q) || s.addressTitle.toLowerCase().contains(q)).toList();
      }
      return list;
    });
  }

  /// جلب الموردين القريبين مع حساب المسافة بالكيلومتر وترتيبهم من الأقرب للأبعد
  Future<List<Map<String, dynamic>>> getNearbySuppliersWithDistance({required GeoPoint userLocation, String? category, double maxRadiusKm = 100.0}) async {
    Query query = _suppliersCollection;
    if (category != null && category.isNotEmpty && category != 'الكل') {
      query = query.where('category', isEqualTo: category);
    }

    final querySnapshot = await query.get();
    final List<Map<String, dynamic>> results = [];

    for (var doc in querySnapshot.docs) {
      final supplier = SupplierModel.fromFirestore(doc);
      if (supplier.location != null) {
        final distanceKm = LocationService.calculateDistanceInKm(userLocation, supplier.location!);

        if (distanceKm <= maxRadiusKm) {
          results.add({'supplier': supplier, 'distanceKm': distanceKm, 'formattedDistance': LocationService.formatDistance(distanceKm)});
        }
      } else {
        results.add({'supplier': supplier, 'distanceKm': 999.0, 'formattedDistance': 'في نطاقك'});
      }
    }

    results.sort((a, b) => (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));
    return results;
  }

  // /// استيراد وزرع أكثر من 1000 محل ومؤسسة ومركز تقني في فايربيز دفعة واحدة (Batch Write)
  // Future<int> seedBulkRealSuppliers({bool force = false}) async {
  //   try {
  //     if (!force) {
  //       final check = await _suppliersCollection.limit(600).get();
  //       if (check.docs.length >= 600) {
  //         return check.docs.length; // تم استيراد قاعدة البيانات الموسعة مسبقاً
  //       }
  //     }

  //     // تقسيم البيانات على دفعات إذا زادت عن 400 (الحد الأقصى لـ WriteBatch هو 500)
  //     const int batchSize = 400;
  //     for (int i = 0; i < kRealSuppliersData.length; i += batchSize) {
  //       final end = (i + batchSize < kRealSuppliersData.length) ? i + batchSize : kRealSuppliersData.length;
  //       final chunk = kRealSuppliersData.sublist(i, end);

  //       final batch = _firestore.batch();
  //       for (var supplier in chunk) {
  //         final docRef = _suppliersCollection.doc(supplier.id);
  //         batch.set(docRef, supplier.toMap(), SetOptions(merge: true));
  //       }
  //       await batch.commit();
  //     }

  //     return kRealSuppliersData.length;
  //   } catch (_) {
  //     return 0;
  //   }
  // }

  // /// دالة التهيئة المبدئية
  // Future<void> seedInitialDemoSuppliersIfEmpty() async {
  //   await seedBulkRealSuppliers(force: false);
  // }
}
