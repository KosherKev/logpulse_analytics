# UI Design Specification - LogPulse Analytics

## 🎨 App Theme & Design System

### Color Palette

#### Primary Colors
```dart
// lib/core/theme/app_colors.dart

// Brand Colors
primary: Color(0xFF2563EB)           // Blue 600 - Main actions, primary buttons
primaryDark: Color(0xFF1E40AF)       // Blue 700 - Active states, pressed
primaryLight: Color(0xFF60A5FA)      // Blue 400 - Hover states
primaryLighter: Color(0xDFBEAFE)     // Blue 100 - Backgrounds, subtle highlights

// Accent Color
accent: Color(0xFF8B5CF6)            // Purple 500 - Secondary actions, highlights

// Status Colors
success: Color(0xFF10B981)           // Green 500 - 2xx responses, healthy status
successLight: Color(0xFFD1FAE5)      // Green 100 - Success backgrounds
warning: Color(0xFFF59E0B)           // Amber 500 - 4xx errors, warnings
warningLight: Color(0xFFFEF3C7)      // Amber 100 - Warning backgrounds
error: Color(0xFFEF4444)             // Red 500 - 5xx errors, critical issues
errorLight: Color(0xFFFEE2E2)        // Red 100 - Error backgrounds
info: Color(0xFF3B82F6)              // Blue 500 - Info messages
debug: Color(0xFF8B5CF6)             // Purple 500 - Debug logs

// Neutral Colors (Light Mode)
background: Color(0xFFF9FAFB)        // Gray 50 - App background
surface: Color(0xFFFFFFFF)           // White - Card/surface background
surfaceVariant: Color(0xFFF3F4F6)    // Gray 100 - Alternate surface
border: Color(0xFFE5E7EB)            // Gray 200 - Borders, dividers
textPrimary: Color(0xFF111827)       // Gray 900 - Primary text
textSecondary: Color(0xFF6B7280)     // Gray 500 - Secondary text
textDisabled: Color(0xFF9CA3AF)      // Gray 400 - Disabled text

// Dark Mode Colors
darkBackground: Color(0xFF0F172A)    // Slate 900 - App background
darkSurface: Color(0xFF1E293B)       // Slate 800 - Card/surface background
darkSurfaceVariant: Color(0xFF334155) // Slate 700 - Alternate surface
darkBorder: Color(0xFF475569)        // Slate 600 - Borders, dividers
darkTextPrimary: Color(0xFFF1F5F9)   // Slate 100 - Primary text
darkTextSecondary: Color(0xFFCBD5E1) // Slate 300 - Secondary text
```

#### Typography
```dart
// lib/core/theme/app_text_styles.dart

// Headings
h1: TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.5,
  height: 1.2,
)

h2: TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.25,
  height: 1.3,
)

h3: TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  letterSpacing: 0,
  height: 1.4,
)

h4: TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w500,
  letterSpacing: 0,
  height: 1.4,
)

// Body Text
bodyLarge: TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.15,
  height: 1.5,
)

body: TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.25,
  height: 1.5,
)

bodySmall: TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.4,
  height: 1.4,
)

// Special
caption: TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.4,
  color: textSecondary,
)

overline: TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w500,
  letterSpacing: 1.5,
  textTransform: uppercase,
)

code: TextStyle(
  fontFamily: 'SF Mono', // or 'Consolas', 'Courier New'
  fontSize: 14,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
)

codeSmall: TextStyle(
  fontFamily: 'SF Mono',
  fontSize: 12,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
)
```

#### Spacing System
```dart
// lib/core/theme/app_spacing.dart

xs: 4.0      // Tiny gaps
sm: 8.0      // Small gaps, chip padding
md: 16.0     // Standard padding, card padding
lg: 24.0     // Section spacing
xl: 32.0     // Large section spacing
xxl: 48.0    // Extra large spacing
```

#### Border Radius
```dart
// lib/core/theme/app_dimensions.dart

radiusSm: 6.0      // Small elements (chips, badges)
radiusMd: 12.0     // Cards, buttons, inputs
radiusLg: 16.0     // Modals, large cards
radiusXl: 24.0     // Bottom sheets, dialogs
radiusFull: 999.0  // Pills, circular buttons
```

#### Elevation/Shadows
```dart
// lib/core/theme/app_shadows.dart

shadow1: BoxShadow(
  color: Color(0x0F000000), // 6% opacity
  offset: Offset(0, 1),
  blurRadius: 2,
)

shadow2: BoxShadow(
  color: Color(0x14000000), // 8% opacity
  offset: Offset(0, 2),
  blurRadius: 8,
)

shadow3: BoxShadow(
  color: Color(0x1F000000), // 12% opacity
  offset: Offset(0, 4),
  blurRadius: 16,
)

shadow4: BoxShadow(
  color: Color(0x29000000), // 16% opacity
  offset: Offset(0, 8),
  blurRadius: 24,
)
```

---

## 📱 Page-by-Page UI Specifications

### 1. Dashboard Page
**File:** `lib/presentation/pages/dashboard/dashboard_page.dart`

#### Layout Structure
```
┌─────────────────────────────────────────┐
│ AppBar: "Dashboard"              [↻] [⚙] │
├─────────────────────────────────────────┤
│ [Time Range Selector: Last 24h ▼]       │ ← Chip-style selector
├─────────────────────────────────────────┤
│ Stats Grid (2x2)                         │
│ ┌──────────────┬──────────────┐         │
│ │ 📊 Total     │ ⚠️ Error    │         │
│ │ 45,234       │ 2.3%         │         │
│ │ ↑ 12.5%     │ ↓ 0.5%      │         │
│ └──────────────┴──────────────┘         │
│ ┌──────────────┬──────────────┐         │
│ │ ⚡ Latency   │ 📈 Requests │         │
│ │ 245ms        │ 12.4k/hr     │         │
│ │ → Stable     │ ↑ 8.2%      │         │
│ └──────────────┴──────────────┘         │
├─────────────────────────────────────────┤
│ Error Rate Chart (Last 24h)             │
│ ┌─────────────────────────────────┐     │
│ │    📈 Line Chart                 │     │
│ │    (fl_chart visualization)      │     │
│ └─────────────────────────────────┘     │
├─────────────────────────────────────────┤
│ Service Health                           │
│ ┌─────────────────────────────────┐     │
│ │ 🟢 user-api          99.8% ✓   │     │
│ │    245ms • 12.4k req             │     │
│ ├─────────────────────────────────┤     │
│ │ 🟡 payment-api       97.2% ⚠   │     │
│ │    456ms • 8.9k req              │     │
│ ├─────────────────────────────────┤     │
│ │ 🟢 order-api         99.1% ✓   │     │
│ │    189ms • 6.2k req              │     │
│ └─────────────────────────────────┘     │
├─────────────────────────────────────────┤
│ Recent Critical Errors                   │
│ ┌─────────────────────────────────┐     │
│ │ 🔴 500 • payment-api             │     │
│ │ Database connection timeout      │     │
│ │ 2 min ago                        │     │
│ └─────────────────────────────────┘     │
└─────────────────────────────────────────┘
```

#### UI Components to Create

**File:** `lib/presentation/widgets/dashboard/stats_grid.dart`
```dart
// 2x2 Grid of StatCard widgets
// Responsive: 1 column on small screens, 2 columns on tablets
Container(
  padding: EdgeInsets.all(16),
  child: GridView.count(
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    children: [
      AnimatedStatCard(...), // With animation on load
      AnimatedStatCard(...),
      AnimatedStatCard(...),
      AnimatedStatCard(...),
    ],
  ),
)
```

**File:** `lib/presentation/widgets/dashboard/error_rate_chart.dart`
```dart
// Line chart showing error rate over time
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Error Rate', style: h3),
            ChipSelector(['1H', '6H', '24H', '7D']),
          ],
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart( // fl_chart
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: [...],
                  isCurved: true,
                  color: error,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: error.withOpacity(0.1),
                  ),
                ),
              ],
              // Grid, titles, tooltips...
            ),
          ),
        ),
      ],
    ),
  ),
)
```

**File:** `lib/presentation/widgets/dashboard/service_health_list.dart`
```dart
// List of service health cards
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Service Health', style: h3),
          TextButton(
            onPressed: () => /* View All */,
            child: Text('View All'),
          ),
        ],
      ),
    ),
    ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: services.length,
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        return EnhancedServiceHealthCard(
          service: services[index],
          onTap: () => /* Navigate to service details */,
        );
      },
    ),
  ],
)
```

**File:** `lib/presentation/widgets/dashboard/recent_errors_list.dart`
```dart
// Recent critical errors - Compact cards
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text('Recent Critical Errors', style: h3),
    ),
    ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: min(recentErrors.length, 5),
      itemBuilder: (context, index) {
        return CompactErrorCard(
          error: recentErrors[index],
          onTap: () => /* Navigate to error details */,
        );
      },
    ),
  ],
)
```

**File:** `lib/presentation/widgets/dashboard/time_range_selector.dart`
```dart
// Horizontal chip selector for time ranges
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Row(
    children: [
      'Last Hour',
      'Last 24h',
      'Last 7 Days',
      'Last 30 Days',
      'Custom',
    ].map((label) {
      final isSelected = selectedRange == label;
      return Padding(
        padding: EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onRangeChanged(label);
          },
          selectedColor: primary,
          backgroundColor: surfaceVariant,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      );
    }).toList(),
  ),
)
```

---

### 2. Logs Page
**File:** `lib/presentation/pages/logs/logs_page.dart`

#### Layout Structure
```
┌─────────────────────────────────────────┐
│ AppBar: "Logs"                   [🔍] [⚙] │
│ ┌─────────────────────────────────────┐ │
│ │ 🔍 Search logs, trace IDs...        │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ Active Filters (if any)                  │
│ [user-api ×] [error ×] [500 ×]  [+More] │
├─────────────────────────────────────────┤
│ Sort: [Most Recent ▼]  [Filter]         │
├─────────────────────────────────────────┤
│ Log List (Infinite Scroll)               │
│ ┌─────────────────────────────────────┐ │
│ │ [INFO] 2:30 PM    🟦              │ │
│ │ user-api • POST /api/users        │ │
│ │ 201 • 45ms                         │ │
│ │ User created successfully          │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ [ERROR] 2:28 PM   🔴              │ │
│ │ payment-api • POST /api/charge    │ │
│ │ 500 • 2.3s                         │ │
│ │ Database connection timeout        │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ [WARN] 2:25 PM    🟧               │ │
│ │ order-api • GET /api/orders/123   │ │
│ │ 404 • 123ms                        │ │
│ │ Order not found                    │ │
│ └─────────────────────────────────────┘ │
│                                          │
│ [Loading more...]                        │
└─────────────────────────────────────────┘
```

#### UI Components to Create

**File:** `lib/presentation/widgets/logs/enhanced_log_card.dart`
```dart
// Enhanced log card with better visual hierarchy
Card(
  elevation: 1,
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(
      color: _getLevelColor(log.level).withOpacity(0.3),
      width: 2,
    ),
  ),
  child: InkWell(
    onTap: () => onTap(),
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Level Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: levelColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getLevelIcon(log.level), size: 14, color: levelColor),
                    SizedBox(width: 4),
                    Text(
                      log.level.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: levelColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              // Service Name
              Expanded(
                child: Text(
                  log.service,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              // Status Code Badge
              if (log.statusCode != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    log.statusCode.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: textSecondary),
            ],
          ),
          SizedBox(height: 12),
          
          // Request Info
          if (log.method != null && log.path != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: surfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Text(
                    log.method!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'SF Mono',
                      color: primary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.path!,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'SF Mono',
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 8),
          
          // Metadata Row
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: textSecondary),
              SizedBox(width: 4),
              Text(
                DateUtils.formatRelative(log.timestamp),
                style: caption,
              ),
              if (log.duration != null) ...[
                SizedBox(width: 12),
                Icon(Icons.speed, size: 14, color: textSecondary),
                SizedBox(width: 4),
                Text(
                  FormatUtils.formatDuration(log.duration!),
                  style: caption,
                ),
              ],
              if (log.traceId != null) ...[
                SizedBox(width: 12),
                Icon(Icons.fingerprint, size: 14, color: textSecondary),
                SizedBox(width: 4),
                Text(
                  'Trace: ${log.traceId!.substring(0, 8)}...',
                  style: caption.copyWith(fontFamily: 'SF Mono'),
                ),
              ],
            ],
          ),
          
          // Error Message (if present)
          if (log.error?.message != null) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: errorLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: error),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.error!.message!,
                      style: TextStyle(
                        fontSize: 13,
                        color: error,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  ),
)
```

**File:** `lib/presentation/widgets/logs/search_bar_widget.dart`
```dart
// Enhanced search bar with clear button and filters
Container(
  margin: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: border),
    boxShadow: [shadow1],
  ),
  child: TextField(
    controller: searchController,
    decoration: InputDecoration(
      hintText: 'Search logs, trace IDs, messages...',
      hintStyle: TextStyle(color: textSecondary),
      prefixIcon: Icon(Icons.search, color: textSecondary),
      suffixIcon: searchController.text.isNotEmpty
        ? IconButton(
            icon: Icon(Icons.clear, color: textSecondary),
            onPressed: () {
              searchController.clear();
              onClear();
            },
          )
        : IconButton(
            icon: Icon(Icons.tune, color: textSecondary),
            onPressed: () => onFilterTap(),
          ),
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    onSubmitted: (value) => onSearch(value),
  ),
)
```

**File:** `lib/presentation/widgets/logs/filter_chips_bar.dart`
```dart
// Horizontal scrollable filter chips
if (activeFilters.isNotEmpty)
  Container(
    height: 48,
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        ...activeFilters.map((filter) {
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(filter.label),
              deleteIcon: Icon(Icons.close, size: 16),
              onDeleted: () => onRemoveFilter(filter),
              backgroundColor: primary.withOpacity(0.1),
              deleteIconColor: primary,
              labelStyle: TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          );
        }),
        // Add More button
        ActionChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16),
              SizedBox(width: 4),
              Text('More Filters'),
            ],
          ),
          onPressed: () => onAddFilter(),
          backgroundColor: surfaceVariant,
        ),
      ],
    ),
  )
```

**File:** `lib/presentation/widgets/logs/sort_filter_bar.dart`
```dart
// Sort and filter controls
Container(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: BoxDecoration(
    color: surface,
    border: Border(
      bottom: BorderSide(color: border, width: 1),
    ),
  ),
  child: Row(
    children: [
      Text('Sort:', style: bodySmall.copyWith(color: textSecondary)),
      SizedBox(width: 8),
      DropdownButton<String>(
        value: currentSort,
        underline: SizedBox(),
        items: [
          DropdownMenuItem(value: 'recent', child: Text('Most Recent')),
          DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
          DropdownMenuItem(value: 'duration', child: Text('Slowest First')),
        ],
        onChanged: (value) => onSortChange(value),
      ),
      Spacer(),
      OutlinedButton.icon(
        onPressed: () => onFilterTap(),
        icon: Icon(Icons.filter_list, size: 18),
        label: Text('Filter'),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    ],
  ),
)
```

---

### 3. Errors Page
**File:** `lib/presentation/pages/errors/errors_page.dart`

#### Layout Structure
```
┌─────────────────────────────────────────┐
│ AppBar: "Errors"              [🔍] [↻] │
├─────────────────────────────────────────┤
│ Summary Cards (Horizontal Scroll)       │
│ ┌────┬────┬────┬────┬────┐            │
│ │All │5xx │4xx │Warn│Crit│            │
│ │124 │45  │67  │12  │8   │            │
│ └────┴────┴────┴────┴────┘            │
├─────────────────────────────────────────┤
│ Error Groups                             │
│ ┌─────────────────────────────────────┐ │
│ │ 🔴 Database connection timeout (45) │ │
│ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │ │
│ │ payment-api, order-api              │ │
│ │ Last: 2 min ago • Trending ↑ 35%   │ │
│ │                                     │ │
│ │ [View All (45)] [Mark Resolved]    │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ 🟡 Validation error (23)            │ │
│ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │ │
│ │ user-api                            │ │
│ │ Last: 15 min ago • Stable           │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

#### UI Components to Create

**File:** `lib/presentation/widgets/errors/error_summary_cards.dart`
```dart
// Horizontal scrolling summary cards
Container(
  height: 100,
  padding: EdgeInsets.symmetric(vertical: 8),
  child: ListView(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.symmetric(horizontal: 16),
    children: [
      _buildSummaryCard('All Errors', totalErrors, Colors.grey, true),
      SizedBox(width: 12),
      _buildSummaryCard('5xx Errors', serverErrors, error, false),
      SizedBox(width: 12),
      _buildSummaryCard('4xx Errors', clientErrors, warning, false),
      SizedBox(width: 12),
      _buildSummaryCard('Warnings', warnings, info, false),
      SizedBox(width: 12),
      _buildSummaryCard('Critical', critical, error, false),
    ],
  ),
)

Widget _buildSummaryCard(String label, int count, Color color, bool isSelected) {
  return Container(
    width: 120,
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isSelected ? color.withOpacity(0.1) : surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isSelected ? color : border,
        width: isSelected ? 2 : 1,
      ),
      boxShadow: isSelected ? [shadow2] : [shadow1],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: bodySmall.copyWith(
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
```

**File:** `lib/presentation/widgets/errors/error_group_card.dart`
```dart
// Enhanced error group card with better design
Card(
  elevation: 2,
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: InkWell(
    onTap: () => onTap(),
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Severity Indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getSeverityColor(group.severity),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getSeverityColor(group.severity).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              // Error Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.message,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (group.errorCode != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'Code: ${group.errorCode}',
                        style: caption.copyWith(
                          fontFamily: 'SF Mono',
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Count Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getSeverityColor(group.severity).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getSeverityColor(group.severity).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  group.count.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _getSeverityColor(group.severity),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Progress Bar (showing error distribution over time)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _getErrorTrendValue(group),
              minHeight: 6,
              backgroundColor: surfaceVariant,
              valueColor: AlwaysStoppedAnimation(
                _getSeverityColor(group.severity),
              ),
            ),
          ),
          
          SizedBox(height: 12),
          
          // Metadata Row
          Row(
            children: [
              // Services
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.dns_outlined, size: 14, color: textSecondary),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        group.formattedServices,
                        style: caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              // Last Seen
              Icon(Icons.access_time, size: 14, color: textSecondary),
              SizedBox(width: 4),
              Text(
                DateUtils.formatRelative(group.lastSeen),
                style: caption,
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Trend Indicator
          if (group.trend != TrendDirection.stable)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: group.trend == TrendDirection.increasing
                    ? error.withOpacity(0.1)
                    : success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    group.trend == TrendDirection.increasing
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 14,
                    color: group.trend == TrendDirection.increasing
                        ? error
                        : success,
                  ),
                  SizedBox(width: 4),
                  Text(
                    group.trend == TrendDirection.increasing
                        ? 'Increasing'
                        : 'Decreasing',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: group.trend == TrendDirection.increasing
                          ? error
                          : success,
                    ),
                  ),
                ],
              ),
            ),
          
          SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onViewAll(),
                  icon: Icon(Icons.list, size: 16),
                  label: Text('View All (${group.count})'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => onMarkResolved(),
                  icon: Icon(Icons.check, size: 16),
                  label: Text('Mark Resolved'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
)
```

---

### 4. Log Details Page
**File:** `lib/presentation/pages/log_details/log_details_page.dart`

#### Layout Structure
```
┌─────────────────────────────────────────┐
│ [←] Log Details              [Share] [⋮] │
├─────────────────────────────────────────┤
│ Header Card                              │
│ ┌─────────────────────────────────────┐ │
│ │ [ERROR] payment-api      [500]      │ │
│ │                                     │ │
│ │ POST /api/payments/charge           │ │
│ │ Duration: 2.3s                      │ │
│ │                                     │ │
│ │ 🔗 Trace: abc-123-xyz  [Copy]      │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ [Overview][Request][Response][Error][Timeline] │
├─────────────────────────────────────────┤
│ Tab Content Area                         │
│ (Dynamic based on selected tab)          │
└─────────────────────────────────────────┘
```

#### UI Components to Create

**File:** `lib/presentation/widgets/log_details/enhanced_log_header.dart`
```dart
// Enhanced header card with glassmorphism effect
Container(
  margin: EdgeInsets.all(16),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        _getLevelColor(log.level).withOpacity(0.1),
        _getLevelColor(log.level).withOpacity(0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: _getLevelColor(log.level).withOpacity(0.3),
      width: 1.5,
    ),
    boxShadow: [shadow3],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Level + Service + Status
            Row(
              children: [
                // Level Badge with icon
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: levelColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getLevelIcon(log.level), size: 16, color: levelColor),
                      SizedBox(width: 6),
                      Text(
                        log.level.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: levelColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    log.service,
                    style: h3.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (log.statusCode != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      log.statusCode.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Request Method and Path
            if (log.method != null && log.path != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.method!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'SF Mono',
                          color: primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        log.path!,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'SF Mono',
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 12),
            
            // Duration and Timestamp
            Row(
              children: [
                if (log.duration != null) ...[
                  Icon(Icons.speed, size: 16, color: textSecondary),
                  SizedBox(width: 4),
                  Text(
                    'Duration: ${FormatUtils.formatDuration(log.duration!)}',
                    style: bodySmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 16),
                ],
                Icon(Icons.access_time, size: 16, color: textSecondary),
                SizedBox(width: 4),
                Text(
                  DateUtils.formatFull(log.timestamp),
                  style: bodySmall,
                ),
              ],
            ),
            
            // Trace ID
            if (log.traceId != null) ...[
              SizedBox(height: 12),
              Divider(height: 1),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.fingerprint, size: 18, color: primary),
                  SizedBox(width: 8),
                  Text(
                    'Trace ID:',
                    style: bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.traceId!,
                      style: bodySmall.copyWith(
                        fontFamily: 'SF Mono',
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 18),
                    onPressed: () => _copyTraceId(),
                    tooltip: 'Copy Trace ID',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  ),
)
```

**File:** `lib/presentation/widgets/log_details/json_viewer_widget.dart`
```dart
// Enhanced JSON viewer with syntax highlighting
Card(
  elevation: 1,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header with controls
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.code, size: 20, color: primary),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            // Pretty Print Toggle
            IconButton(
              icon: Icon(
                prettyPrint ? Icons.wrap_text : Icons.code,
                size: 20,
                color: primary,
              ),
              onPressed: () => setState(() => prettyPrint = !prettyPrint),
              tooltip: prettyPrint ? 'Raw' : 'Pretty',
            ),
            // Copy Button
            IconButton(
              icon: Icon(Icons.copy, size: 20, color: primary),
              onPressed: () => _copyToClipboard(),
              tooltip: 'Copy',
            ),
            // Expand/Collapse Button
            IconButton(
              icon: Icon(
                expanded ? Icons.unfold_less : Icons.unfold_more,
                size: 20,
                color: primary,
              ),
              onPressed: () => setState(() => expanded = !expanded),
              tooltip: expanded ? 'Collapse' : 'Expand',
            ),
          ],
        ),
      ),
      
      // JSON Content
      AnimatedContainer(
        duration: Duration(milliseconds: 300),
        constraints: BoxConstraints(
          maxHeight: expanded ? double.infinity : 300,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: SelectableText(
            formattedJson,
            style: TextStyle(
              fontFamily: 'SF Mono',
              fontSize: 13,
              height: 1.5,
              color: textPrimary,
            ),
            // TODO: Add syntax highlighting
          ),
        ),
      ),
    ],
  ),
)
```

**File:** `lib/presentation/pages/log_details/tabs/enhanced_timeline_tab.dart`
```dart
// Visual timeline with better design
ListView(
  padding: EdgeInsets.all(16),
  children: [
    // Duration Summary with circular progress
    Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            // Circular Progress Indicator
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                children: [
                  CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    backgroundColor: surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(primary),
                  ),
                  Center(
                    child: Icon(
                      Icons.timer,
                      size: 32,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Duration', style: caption),
                  SizedBox(height: 4),
                  Text(
                    FormatUtils.formatDuration(log.duration!),
                    style: h2.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    DateUtils.formatFull(log.timestamp),
                    style: bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    
    SizedBox(height: 24),
    
    // Timeline Events
    Text(
      'Request Timeline',
      style: h3.copyWith(fontWeight: FontWeight.w600),
    ),
    SizedBox(height: 16),
    
    ...events.map((event) => _buildTimelineItem(event)),
    
    SizedBox(height: 24),
    
    // Performance Breakdown
    Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, size: 20, color: primary),
                SizedBox(width: 8),
                Text(
                  'Performance Breakdown',
                  style: h4.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 20),
            ...breakdownItems.map((item) => _buildBreakdownBar(item)),
          ],
        ),
      ),
    ),
  ],
)

Widget _buildTimelineItem(TimelineEvent event) {
  return Padding(
    padding: EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline decoration
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: event.isError ? error : primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: surface,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (event.isError ? error : primary).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            if (!event.isLast)
              Container(
                width: 2,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (event.isError ? error : primary).withOpacity(0.5),
                      (event.isError ? error : primary).withOpacity(0.1),
                    ],
                  ),
                ),
              ),
          ],
        ),
        
        SizedBox(width: 16),
        
        // Event content
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: event.isError ? errorLight : surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: event.isError
                    ? error.withOpacity(0.3)
                    : border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        event.timestamp,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF Mono',
                          color: primary,
                        ),
                      ),
                    ),
                    if (event.isError) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ERROR',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: event.isError ? error : textPrimary,
                  ),
                ),
                if (event.description != null) ...[
                  SizedBox(height: 4),
                  Text(
                    event.description!,
                    style: bodySmall.copyWith(color: textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildBreakdownBar(BreakdownItem item) {
  return Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  item.label,
                  style: bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Text(
              '${FormatUtils.formatDuration(item.duration)} (${item.percentage.toStringAsFixed(1)}%)',
              style: bodySmall.copyWith(
                fontFamily: 'SF Mono',
                color: textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: item.percentage / 100,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      item.color,
                      item.color.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
```

---

### 5. Settings Page
**File:** `lib/presentation/pages/settings/settings_page.dart`

#### Layout Structure
```
┌─────────────────────────────────────────┐
│ AppBar: "Settings"                       │
├─────────────────────────────────────────┤
│ API Configuration                        │
│ ┌─────────────────────────────────────┐ │
│ │ 🔗 Service URL                      │ │
│ │ https://your-service.run.app        │ │
│ │                                     │ │
│ │ 🔑 API Key                          │ │
│ │ ****************************        │ │
│ │                                     │ │
│ │ ✓ Connected                  [Edit] │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ Appearance                               │
│ ┌─────────────────────────────────────┐ │
│ │ 🌙 Theme Mode                       │ │
│ │ System Default                   >  │ │
│ │                                     │ │
│ │ 🎨 Accent Color                     │ │
│ │ [🔵] [🟣] [🟢] [🟠] [🔴]          │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ Refresh Settings                         │
│ ┌─────────────────────────────────────┐ │
│ │ ↻ Auto Refresh              [ON]   │ │
│ │ 📊 Refresh Interval         30s  >  │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ About                                    │
│ ┌─────────────────────────────────────┐ │
│ │ ℹ️ Version         1.0.0            │ │
│ │ 📖 Documentation                 >  │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

#### UI Components to Create

**File:** `lib/presentation/widgets/settings/api_config_card.dart`
```dart
// API configuration card with connection status
Card(
  elevation: 2,
  margin: EdgeInsets.all(16),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  child: Padding(
    padding: EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.cloud, color: primary, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API Configuration',
                    style: h4.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isConnected ? success : error,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isConnected ? success : error).withOpacity(0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        isConnected ? 'Connected' : 'Not Connected',
                        style: bodySmall.copyWith(
                          color: isConnected ? success : error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isConfigured)
              OutlinedButton(
                onPressed: () => onEdit(),
                child: Text('Edit'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
          ],
        ),
        
        if (isConfigured) ...[
          SizedBox(height: 20),
          Divider(height: 1),
          SizedBox(height: 20),
          
          // Service URL
          _buildInfoRow(
            icon: Icons.link,
            label: 'Service URL',
            value: serviceUrl,
            isUrl: true,
          ),
          
          SizedBox(height: 16),
          
          // API Key (masked)
          _buildInfoRow(
            icon: Icons.vpn_key,
            label: 'API Key',
            value: showApiKey ? apiKey : '•' * 32,
            isSensitive: true,
            onToggleVisibility: () => setState(() => showApiKey = !showApiKey),
          ),
        ] else ...[
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onConfigure(),
              icon: Icon(Icons.settings),
              label: Text('Configure API'),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ],
    ),
  ),
)

Widget _buildInfoRow({
  required IconData icon,
  required String label,
  required String value,
  bool isUrl = false,
  bool isSensitive = false,
  VoidCallback? onToggleVisibility,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: textSecondary),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: caption.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: bodySmall.copyWith(
                fontFamily: isUrl || isSensitive ? 'SF Mono' : null,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      if (isSensitive && onToggleVisibility != null)
        IconButton(
          icon: Icon(
            showApiKey ? Icons.visibility_off : Icons.visibility,
            size: 18,
          ),
          onPressed: onToggleVisibility,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
        ),
    ],
  );
}
```

**File:** `lib/presentation/widgets/settings/theme_selector.dart`
```dart
// Theme mode selector with preview
Card(
  elevation: 1,
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Column(
    children: [
      ListTile(
        leading: Icon(Icons.brightness_6, color: primary),
        title: Text('Theme Mode', style: bodyLarge.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(currentTheme, style: bodySmall),
        trailing: Icon(Icons.chevron_right, color: textSecondary),
        onTap: () => _showThemePicker(),
      ),
    ],
  ),
)

// Theme picker dialog
void _showThemePicker() {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Theme',
              style: h3.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 20),
            _buildThemeOption(
              'Light Mode',
              Icons.light_mode,
              'light',
              'Perfect for daytime use',
            ),
            SizedBox(height: 12),
            _buildThemeOption(
              'Dark Mode',
              Icons.dark_mode,
              'dark',
              'Easy on the eyes at night',
            ),
            SizedBox(height: 12),
            _buildThemeOption(
              'System Default',
              Icons.brightness_auto,
              'system',
              'Follows your device settings',
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildThemeOption(String title, IconData icon, String value, String description) {
  final isSelected = currentTheme == value;
  
  return InkWell(
    onTap: () {
      onThemeChanged(value);
      Navigator.pop(context);
    },
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? primary.withOpacity(0.1) : surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? primary : border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? primary.withOpacity(0.2) : surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isSelected ? primary : textSecondary,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: bodyLarge.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? primary : textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: caption,
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle, color: primary, size: 24),
        ],
      ),
    ),
  );
}
```

---

## 📁 File Structure Summary

### New Files to Create

```
lib/
├── core/
│   └── theme/
│       ├── app_colors.dart              ✨ NEW - Color definitions
│       ├── app_text_styles.dart         ✨ NEW - Typography styles
│       ├── app_spacing.dart             ✨ NEW - Spacing constants
│       ├── app_dimensions.dart          ✨ NEW - Border radius, sizes
│       ├── app_shadows.dart             ✨ NEW - Shadow definitions
│       └── app_theme.dart               ✨ NEW - Theme data builder
│
└── presentation/
    └── widgets/
        ├── dashboard/
        │   ├── stats_grid.dart          ✨ NEW - 2x2 stats grid
        │   ├── error_rate_chart.dart    ✨ NEW - fl_chart line chart
        │   ├── service_health_list.dart ✨ NEW - Service list
        │   ├── recent_errors_list.dart  ✨ NEW - Recent errors
        │   └── time_range_selector.dart ✨ NEW - Chip selector
        │
        ├── logs/
        │   ├── enhanced_log_card.dart   ✨ NEW - Better log card
        │   ├── search_bar_widget.dart   ✨ NEW - Search with clear
        │   ├── filter_chips_bar.dart    ✨ NEW - Active filter chips
        │   └── sort_filter_bar.dart     ✨ NEW - Sort dropdown + filter button
        │
        ├── errors/
        │   ├── error_summary_cards.dart ✨ NEW - Horizontal summary cards
        │   └── error_group_card.dart    ✨ NEW - Enhanced error card
        │
        ├── log_details/
        │   ├── enhanced_log_header.dart ✨ NEW - Glassmorphism header
        │   └── json_viewer_widget.dart  ✨ NEW - JSON with syntax highlighting
        │
        └── settings/
            ├── api_config_card.dart     ✨ NEW - API configuration
            └── theme_selector.dart      ✨ NEW - Theme picker

Total New Files: ~30 UI component files
```

---

## 🎨 Design System Summary

### Theme Colors
- **Primary:** Blue (#2563EB)
- **Accent:** Purple (#8B5CF6)
- **Success:** Green (#10B981) - for 2xx, healthy
- **Warning:** Amber (#F59E0B) - for 4xx
- **Error:** Red (#EF4444) - for 5xx, critical

### Typography
- **Headings:** 32px/24px/20px/18px
- **Body:** 16px/14px/12px
- **Code:** SF Mono or Consolas
- **Weight:** 400 (regular), 500 (medium), 600 (semibold), 700 (bold)

### Spacing
- xs: 4px, sm: 8px, md: 16px, lg: 24px, xl: 32px, xxl: 48px

### Border Radius
- sm: 6px (chips), md: 12px (cards), lg: 16px (modals), xl: 24px (sheets)

### Shadows
- 4 levels of elevation with increasing blur and opacity

---

## 🚀 Implementation Priority

### Phase 1: Theme System
1. Create all theme files in `lib/core/theme/`
2. Update `app.dart` to use new theme
3. Test light/dark mode switching

### Phase 2: Dashboard Enhancements
4. Create dashboard widgets
5. Integrate fl_chart for error rate chart
6. Add time range selector
7. Enhance service health cards

### Phase 3: Logs Improvements
8. Create enhanced log cards
9. Add search bar widget
10. Implement filter chips
11. Add sort/filter bar

### Phase 4: Errors Page
12. Create error summary cards
13. Enhance error group cards
14. Add trend visualizations

### Phase 5: Log Details Polish
15. Create glassmorphism header
16. Add JSON viewer with syntax highlighting
17. Enhance timeline visualization
18. Add performance breakdown charts

### Phase 6: Settings
19. Create API config card
20. Add theme selector
21. Polish all settings UI

---

This specification provides a complete blueprint for creating a beautiful, modern UI for the LogPulse Analytics app. The design emphasizes clarity, visual hierarchy, and delightful interactions while maintaining excellent usability.
