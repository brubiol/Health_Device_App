// import 'package:flutter/material.dart';
// import 'package:health_device_app/models/metric.dart';

// List<Metric> metrics = [
//   Metric(
//       title: 'Heart Rate',
//       value: '...',
//       icon: Icons.favorite,
//       color: Colors.red),
//   Metric(
//       title: 'Blood Oxygen',
//       value: '...',
//       icon: Icons.opacity,
//       color: Colors.blue),
//   Metric(
//       title: 'Temperature',
//       value: '...',
//       icon: Icons.thermostat,
//       color: Colors.orange),
// ];

// class EssentialMetricsGridView extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
//       child: GridView.builder(
//         padding: EdgeInsets.zero,
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           crossAxisSpacing: 10,
//           mainAxisSpacing: 10,
//           childAspectRatio: 1,
//         ),
//         primary: false,
//         shrinkWrap: true,
//         scrollDirection: Axis.vertical,
//         itemBuilder: (context, index) {
//           Metric metric = metrics[index];
//           return Container(
//             width: MediaQuery.of(context).size.width * 0.4,
//             height: 160,
//             decoration: BoxDecoration(
//               color: Color(0xFFF1F4F8),
//               borderRadius: BorderRadius.circular(24),
//             ),
//             child: Padding(
//               padding: EdgeInsetsDirectional.fromSTEB(12, 12, 12, 12),
//               child: Column(
//                 mainAxisSize: MainAxisSize.max,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     metric.icon,
//                     color: metric.color,
//                     size: 32,
//                   ),
//                   Padding(
//                     padding: EdgeInsetsDirectional.fromSTEB(0, 12, 0, 12),
//                     child: Text(
//                       metric.value,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontFamily: 'Plus Jakarta Sans',
//                         color: Color(0xFF101213),
//                         fontSize: 36,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                   Text(
//                     metric.title,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontFamily: 'Plus Jakarta Sans',
//                       color: Color(0xFF57636C),
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//         itemCount: metrics.length,
//       ),
//     );
//   }
// }
