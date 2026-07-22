part of 'yours_share_poster.dart';

class _PosterContent extends StatelessWidget {
  const _PosterContent({
    required this.data,
    required this.options,
    required this.style,
  });

  final YoursWorkoutShareData data;
  final YoursSharePosterOptions options;
  final _PosterStyle style;

  @override
  Widget build(BuildContext context) {
    final note = data.note.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PosterHeader(data: data, options: options, style: style),
        const SizedBox(height: 196),
        if (options.showWorkoutName) _PosterHero(data: data, style: style),
        const SizedBox(height: 104),
        _PosterMetrics(data: data, options: options, style: style),
        if (options.showNote && note.isNotEmpty) ...[
          const SizedBox(height: 34),
          _PosterNoteBlock(
            style: style,
            note: note,
          ),
        ],
        const Spacer(),
        if (options.showBrand) _PosterFooter(style: style),
      ],
    );
  }
}

class _PosterHeader extends StatelessWidget {
  const _PosterHeader({
    required this.data,
    required this.options,
    required this.style,
  });

  final YoursWorkoutShareData data;
  final YoursSharePosterOptions options;
  final _PosterStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (options.showBrand) ...[
          Row(
            children: [
              _PosterMark(style: style),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yours', style: style.brandName),
                  const SizedBox(height: 8),
                  Text('有思', style: style.brandSub),
                ],
              ),
            ],
          ),
        ],
        const Spacer(),
        if (options.showDate)
          Text(
            '${data.recordLabel}\n${_posterDate(data.date)}',
            textAlign: TextAlign.right,
            style: style.recordMeta,
          ),
      ],
    );
  }
}

class _PosterHero extends StatelessWidget {
  const _PosterHero({required this.data, required this.style});

  final YoursWorkoutShareData data;
  final _PosterStyle style;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data.recordLabel, style: style.eyebrow),
        const SizedBox(height: 22),
        Text(
          data.workoutName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style.title,
        ),
        if (data.workoutSubtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            data.workoutSubtitle.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: style.recordMeta,
          ),
        ],
      ],
    );
  }
}

class _PosterMetrics extends StatelessWidget {
  const _PosterMetrics({
    required this.data,
    required this.options,
    required this.style,
  });

  final YoursWorkoutShareData data;
  final YoursSharePosterOptions options;
  final _PosterStyle style;

  @override
  Widget build(BuildContext context) {
    final metrics = <Widget>[
      if (options.showDuration)
        _MetricCard(
          label: '总用时',
          value: '${data.duration.inMinutes}',
          unit: '分钟',
          style: style,
        ),
      if (options.showExerciseCount)
        _MetricCard(
          label: '动作数',
          value: '${data.exerciseCount}',
          unit: '个动作',
          style: style,
        ),
      if (options.showSetCount)
        _MetricCard(label: '总组数', value: '${data.setCount}', unit: '组', style: style),
    ];
    final showVolume = options.showVolume;
    if (metrics.isEmpty && !showVolume) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        if (metrics.isNotEmpty)
          Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                Expanded(child: metrics[i]),
                if (i != metrics.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        if (showVolume) ...[
          if (metrics.isNotEmpty) const SizedBox(height: 16),
          _MetricCard(
            label: '总容量',
            value: _formatVolume(data.totalVolume),
            unit: 'kg',
            style: style,
            wide: true,
          ),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.style,
    this.wide = false,
  });

  final String label;
  final String value;
  final String unit;
  final _PosterStyle style;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final valueText = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(value, style: wide ? style.wideMetricValue : style.metricValue),
          ),
        ),
        const SizedBox(width: 10),
        Text(unit, style: style.metricUnit),
      ],
    );
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: wide ? 132 : 126),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(label, style: style.metricLabel),
                ),
                const Spacer(),
                Expanded(
                  flex: 4,
                  child: Align(alignment: Alignment.bottomRight, child: valueText),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(label, style: style.metricLabel),
                const SizedBox(height: 20),
                valueText,
              ],
            ),
    );
  }
}

class _PosterNoteBlock extends StatelessWidget {
  const _PosterNoteBlock({
    required this.style,
    required this.note,
  });

  final _PosterStyle style;
  final String note;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            style.softTextBackdrop,
            style.softTextBackdrop.withValues(alpha: 0),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 18, 44, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TRAINING NOTE', style: style.noteLabel),
            const SizedBox(height: 18),
            Text(note, maxLines: 4, overflow: TextOverflow.ellipsis, style: style.noteText),
          ],
        ),
      ),
    );
  }
}

class _PosterFooter extends StatelessWidget {
  const _PosterFooter({required this.style});

  final _PosterStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '完成',
                    style: TextStyle(color: style.accent),
                  ),
                  const TextSpan(text: ' · 由有思记录'),
                ],
              ),
              style: style.footerTitle,
            ),
            const SizedBox(height: 12),
            Text('Recorded with Yours', style: style.footerSub),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: style.accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Text('清晰记录，长期保存', style: style.miniRow),
          ],
        ),
      ],
    );
  }
}
