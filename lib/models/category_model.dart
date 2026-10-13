import 'package:flutter/material.dart';

class ServiceCategory {
  final String id;
  final String name;
  final IconData icon;
  final String description;

  const ServiceCategory({required this.id, required this.name, required this.icon, this.description = ''});

  static const List<ServiceCategory> defaultCategories = [
    ServiceCategory(id: 'programming', name: 'برمجة وتطوير تقني', icon: Icons.code, description: 'تطوير مواقع، تطبيقات جوال، أنظمة ومتاجر إلكترونية وحلول برمجية'),
    ServiceCategory(id: 'art_and_design', name: 'فنون وتصميم ورسم', icon: Icons.palette, description: 'رسم جداري، لوحات فنية، خط عربي، ديكورات وتصميم جرافيك'),
    ServiceCategory(id: 'freelance', name: 'عمل حر وفريلانس', icon: Icons.laptop_chromebook, description: 'تسويق رقمي، كتابة محتوى، ترجمة، مونتاج وخدمات رقمية عن بعد'),
    ServiceCategory(id: 'plumbing', name: 'سباكة', icon: Icons.plumbing, description: 'إصلاح تسريبات، تركيب أدوات صحية، وصيانة المواسير'),
    ServiceCategory(id: 'electricity', name: 'كهرباء', icon: Icons.electrical_services, description: 'تركيب وصيانة شبكات الكهرباء، الإضاءة، والأجهزة'),
    ServiceCategory(id: 'ceramics', name: 'سيراميك وبلاط', icon: Icons.wallpaper, description: 'تركيب وصيانة السيراميك، البلاط، والرخام'),
    ServiceCategory(id: 'air_conditioning', name: 'تكييف وتبريد', icon: Icons.ac_unit, description: 'شحن الفريون، صيانة وتنظيف المكيفات'),
    ServiceCategory(id: 'carpentry', name: 'نجارة', icon: Icons.carpenter, description: 'تصليح الأبواب، غرف النوم، وتفصيل المطابخ'),
    ServiceCategory(id: 'painting', name: 'دهانات ونقاشة', icon: Icons.format_paint, description: 'دهان الجدران، ديكورات، ومعالجة الرطوبة'),
    ServiceCategory(id: 'appliances', name: 'أجهزة منزلية', icon: Icons.kitchen, description: 'صيانة الغسالات، الثلاجات، والأفران'),
    ServiceCategory(id: 'moving', name: 'نقل عفش وأثاث', icon: Icons.local_shipping, description: 'فك وتركيب ونقل الأثاث بأمان'),
    ServiceCategory(id: 'cleaning', name: 'نظافة وعمالة', icon: Icons.cleaning_services, description: 'تنظيف المنازل، واجهات، وعمالة باليومية'),
  ];
}
