import 'package:flutter/material.dart';

import '../models/mockup/printfile_model.dart';

class PrintfileOptionsWidget extends StatelessWidget {
  final PrintfileResult printfileResult;
  final Function(int variantId, String placement, int printfileId)?
  onPlacementSelected;

  const PrintfileOptionsWidget({
    super.key,
    required this.printfileResult,
    this.onPlacementSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product info header
        _buildProductInfo(),
        const SizedBox(height: 16),

        // Available placements overview
        _buildAvailablePlacementsOverview(),
        const SizedBox(height: 16),

        // Variant-specific printfile options
        _buildVariantPrintfileOptions(),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Product Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Product ID', printfileResult.product_id.toString()),
            if (printfileResult.option_groups.isNotEmpty)
              _buildInfoRow(
                'Option Groups',
                printfileResult.option_groups.join(', '),
              ),
            if (printfileResult.options.isNotEmpty)
              _buildInfoRow('Options', printfileResult.options.join(', ')),
            _buildInfoRow(
              'Total Variants',
              printfileResult.variant_printfiles.length.toString(),
            ),
            _buildInfoRow(
              'Total Printfiles',
              printfileResult.printfiles.length.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePlacementsOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.place_outlined, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Available Placements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: printfileResult.available_placements.entries.map((
                entry,
              ) {
                return Chip(
                  label: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  backgroundColor: Colors.green.shade50,
                  side: BorderSide(color: Colors.green.shade200),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'These are all possible placement locations for this product type.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantPrintfileOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.style_outlined, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Variant Printfile Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Select a variant to see its supported printfile placements:',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),

            // List of variants with their placements
            ...printfileResult.variant_printfiles.map((variantPrintfile) {
              return _buildVariantCard(variantPrintfile);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantCard(VariantPrintfile variantPrintfile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Variant header
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.purple.shade600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Variant ID: ${variantPrintfile.variant_id}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${variantPrintfile.placements.length} placements',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Placements grid
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Supported Placements:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: variantPrintfile.placements.entries.map((entry) {
                    final placementName = entry.key;
                    final printfileId = entry.value;
                    final printfile = printfileResult.printfiles.firstWhere(
                      (pf) => pf.printfile_id == printfileId,
                      orElse: () => printfileResult.printfiles.first,
                    );

                    return _buildPlacementChip(
                      placementName,
                      printfileId,
                      printfile,
                      variantPrintfile.variant_id,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementChip(
    String placementName,
    int printfileId,
    Printfile printfile,
    int variantId,
  ) {
    final placementDescription =
        printfileResult.available_placements[placementName] ?? placementName;

    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Icon(
          Icons.print_outlined,
          size: 16,
          color: Colors.blue.shade700,
        ),
      ),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            placementName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            placementDescription,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
      backgroundColor: Colors.blue.shade50,
      side: BorderSide(color: Colors.blue.shade200),
      onPressed: onPlacementSelected != null
          ? () => onPlacementSelected!(variantId, placementName, printfileId)
          : null,
      tooltip:
          'Printfile ID: $printfileId\n${printfile.width}x${printfile.height} @ ${printfile.dpi} DPI',
    );
  }
}
