import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/supplier_model.dart';
import '../../services/supplier_service.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/external_launcher.dart';

class SuppliersView extends StatefulWidget {
  final GeoPoint? userLocation;
  final VoidCallback onAddSupplierPressed;

  const SuppliersView({
    super.key,
    this.userLocation,
    required this.onAddSupplierPressed,
  });

  @override
  State<SuppliersView> createState() => _SuppliersViewState();
}

class _SuppliersViewState extends State<SuppliersView> {
  final SupplierService _supplierService = SupplierService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'الكل';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // 1. بانر تعريفي لقسم المون
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade800, Colors.amber.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade900.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront, color: Colors.white, size: 38),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'دليل المون ومحلات البناء في منطقتك',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'أكثر من 200 محل ومورد (رمل وأسمنت، حدايد وبويات، سباكة، وكهرباء) لخدمة الفنيين وأصحاب المشاريع فوراً.',
                        style: TextStyle(color: Colors.orange.shade100, fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. حقل البحث السريع
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث باسم المحل أو المنطقة أو المونة (مثال: رمل، جوتن، أسلاك)...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // 3. شريط فلاتر أقسام المون
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryFilterChip('الكل'),
                  ...SupplierModel.categories.map((c) => _buildCategoryFilterChip(c)),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 10)),

        // 4. قائمة المحلات
        StreamBuilder<List<SupplierModel>>(
          stream: _supplierService.streamSuppliers(
            category: _selectedCategory,
            searchQuery: _searchQuery,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final suppliers = snapshot.data ?? [];

            if (suppliers.isEmpty) {
              return SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.store_mall_directory_outlined, size: 55, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'لا توجد نتائج تطابق بحثك "$_searchQuery".'
                            : 'لا توجد محلات مسجلة في هذا القسم حالياً.',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: widget.onAddSupplierPressed,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('أضف أول محل هنا'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // إذا كان موقع المستخدم متوفراً، نرتب المحلات حسب القرب الجغرافي
            final List<Map<String, dynamic>> sortedList = suppliers.map((s) {
              double distanceKm = 999.0;
              String formattedDistance = 'في منطقتك';

              if (widget.userLocation != null && s.location != null) {
                distanceKm = LocationService.calculateDistanceInKm(
                  widget.userLocation!,
                  s.location!,
                );
                formattedDistance = LocationService.formatDistance(distanceKm);
              }

              return {
                'supplier': s,
                'distanceKm': distanceKm,
                'formattedDistance': formattedDistance,
              };
            }).toList();

            if (widget.userLocation != null) {
              sortedList.sort((a, b) =>
                  (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));
            }

            return SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: Text(
                      'تم العثور على ${sortedList.length} محل ومورد قريب:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = sortedList[index];
                        final SupplierModel supplier = item['supplier'];
                        final String distance = item['formattedDistance'];
                        return _buildSupplierCard(supplier, distance);
                      },
                      childCount: sortedList.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildCategoryFilterChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(category),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        selectedColor: Colors.orange.shade800,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        onSelected: (val) {
          setState(() => _selectedCategory = category);
        },
      ),
    );
  }

  Widget _buildSupplierCard(SupplierModel supplier, String distance) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    supplier.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    supplier.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            if (supplier.ownerName.isNotEmpty)
              Text(
                'المسؤول: ${supplier.ownerName}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),

            const SizedBox(height: 6),
            Text(
              supplier.description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    supplier.addressTitle.isNotEmpty ? supplier.addressTitle : 'المنطقة القريبة',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    distance,
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            if (supplier.deliveryAvailable)
              Row(
                children: [
                  const Icon(Icons.local_shipping, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'يتوفر توصيل ونقل للموقع 🚚',
                    style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w600),
                  ),
                ],
              ),

            const Divider(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ExternalLauncher.makePhoneCall(supplier.phone);
                    },
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('اتصال بالمحل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (supplier.location != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ExternalLauncher.openGoogleMaps(
                          latitude: supplier.location!.latitude,
                          longitude: supplier.location!.longitude,
                        );
                      },
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('الموقع بالخريطة'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blue.shade900,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
