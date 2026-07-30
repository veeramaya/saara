import 'package:flutter/material.dart';

/// One coach card (§20.2 onboarding / Help). Ordered flow — first-run and
/// re-openable from Settings → How Saara works.
class _Card {
  const _Card(
    this.tag,
    this.title,
    this.what,
    this.exampleLabel,
    this.example,
    this.why, {
    this.isNew = false,
  });
  final String tag, title, what, exampleLabel, example, why;
  final bool isNew;
}

const _cards = <_Card>[
  _Card(
    'P-Integrity',
    'A path, not a scorecard.',
    'Integrity here is a path you train, not a position you reach. Saara keeps a simple, honest score of whether you kept your word — and surrounds it with insights, because a number alone is never the whole of who you are.',
    'How it works',
    'The system owns the facts — did it happen, and when. You own the judgment — how well. The people you gave your word to are the mirror. The score is the spine; the growth lives in the insights.',
    'The number is a compass, not a verdict — integrity is trained, not achieved.',
    isNew: true,
  ),
  _Card(
    'How Saara helps',
    'Give your word. Keep it.',
    'Saara turns intentions into a track record, and shows you becoming someone whose word is trusted.',
    'Example',
    'Say “walk 30 min.” Saara holds it, scores it done = +1, and shows you climbing from Beginner → Masterful.',
    'Good intentions become a visible, growing record of reliability.',
  ),
  _Card(
    'Privacy first',
    'Your data stays yours.',
    'Everything lives on your device, encrypted. Realmaya never sees it.',
    'Example',
    'Tasks sit in an encrypted on-device database. AI uses your key. Google sync goes phone → Google directly — no middle server.',
    'A platform about integrity has to be one you can trust.',
  ),
  _Card(
    'Work areas',
    'Organise life into areas.',
    'Health, Career, Relationships, Finance, Growth, Leisure — each carries its own integrity score.',
    'Example',
    'Every kept task in Health lifts that area’s effectiveness; the wheel shows where you’re reliable and where you’re not.',
    'See the shape of your reliability across life, not one flat number.',
  ),
  _Card(
    'Tasks & events',
    'Two kinds of commitment.',
    'A Task is a to-do (syncs with Google Tasks). An Event is time-blocked (syncs both ways with Google Calendar — create it here, it appears there). Both can repeat.',
    'Example',
    '“Team standup, weekly, Mon 9am” → an Event on your Google Calendar. “Call mom Sunday 6pm” → a recurring Task.',
    'The right shape for the right promise — and they render distinctly.',
  ),
  _Card(
    'Capture anything',
    'Type, paste, talk, or snap.',
    'Type it, paste a WhatsApp message, dictate it with the mic, or photograph a note/invite. With your AI key, Saara reads it into fields — you verify against the original.',
    'Example',
    'Screenshot a Zoom invite → “Extract with AI” → an Event with the join link and time. A meeting summary → several tasks to tick and create.',
    'The fastest capture wins — the deterministic parser works with no key too.',
    isNew: true,
  ),
  _Card(
    'Ask Saara',
    'Find and create, in plain words.',
    'The Saara tab understands natural language. Ask to find what you committed, or just say what you want to do — recurrence and all — and Saara turns it into a task you can verify.',
    'Example',
    '“What did I commit with the coaches?” lists them, each tappable. “Gym every Monday 6am” → a recurring task, ready to confirm.',
    'The fastest way in is often just to say what you mean.',
    isNew: true,
  ),
  _Card(
    'Edit & reschedule',
    'Change your mind, cleanly.',
    'Open any task → ✎ Edit → change the title, time, area, links, or location. The update syncs back to Google.',
    'Example',
    'Move a meeting to Friday 4pm → edit once; Saara updates the Google Calendar entry.',
    'Plans change; keeping your word means adjusting honestly, not silently dropping.',
  ),
  _Card(
    'Measurable results',
    'Make “done” unambiguous.',
    'Attach a number to a goal so there’s no “sort of done.”',
    'Example',
    '“Walk 8,000 steps daily.” Hit 8k → kept (+1). Fall short → not kept. No grey zone.',
    'A clear line is what makes a kept word real.',
  ),
  _Card(
    'Money · a measurable',
    'Quantify it, and it’s real.',
    'Money isn’t special — it’s just a measurable result in currency. Set a number in ₹ (or your currency) and it becomes objective reality, scored like steps or minutes.',
    'Example',
    '“Save ₹5,000 this month” or “Earn ₹20,000.” Hit the number → kept (+1), in the area you choose.',
    'A quantified word leaves no room for “sort of” — the number is the truth.',
    isNew: true,
  ),
  _Card(
    'Google sync',
    'One list, every device.',
    'Two-way and automatic — for Google Tasks and Google Calendar events. Create/edit/complete/delete flows both ways, on open, on change, and in the background.',
    'Example',
    'Add a task on your laptop → open Saara on your phone → it’s already there. Make an event in Saara → it’s on your calendar.',
    'Desktop and mobile stay in step without a thought.',
  ),
  _Card(
    'Sync your devices',
    'Your record, on every device — no cloud.',
    'Keep phone and desktop in step directly. Sync over Wi-Fi — one device shows a QR, the other scans it — or share a ledger file between them. It never goes through Google, and carries what Google can’t: your areas, history and provenance.',
    'Example',
    'Both on the same Wi-Fi → Settings → Sync between my devices → Sync over Wi-Fi → show a code on the laptop, scan it on the phone → both match in seconds.',
    'Portable and private — your whole record travels, only ever between your own devices.',
    isNew: true,
  ),
  _Card(
    'Attach & link',
    'Keep the receipts.',
    'Attach an image from your phone, or paste a link — a Google Doc, a Sheet, any URL — onto a task. Saara stores the link; it opens under your own access, no extra permissions.',
    'Example',
    '“Review the MoM before the sync” → paste the doc link → tap Open later.',
    'A kept word you can point to.',
  ),
  _Card(
    'Reminders & arrival',
    'A gentle nudge, in time or place.',
    'Turn on a per-task reminder for a heads-up before it starts. Add a location and “notify me when I arrive” for an on-the-spot prompt.',
    'Example',
    '“Pick up medicine” with the pharmacy’s location → Saara reminds you the moment you’re nearby.',
    'The right nudge at the right moment — never nagging.',
  ),
  _Card(
    'Committed listeners',
    'A word has to land.',
    'Integrity is relational — a promise isn’t fully kept until it lands with the person you gave it to. Add a listener; take their feedback at the summary level.',
    'Example',
    'You commit: “home by 7 on weekdays.” Each week they rate how it felt. Saara compares it to your self-score and suggests.',
    'Doing 100% alone isn’t enough — the listening has to shift too.',
    isNew: true,
  ),
  _Card(
    'People on a task',
    'Call or message, in one tap.',
    'Add a participant with their number, and reach them straight from the task — Call or WhatsApp. The number stays on your device and travels only between your own devices, never through Google.',
    'Example',
    '“Call the plumber” with his number → open the task → tap Call or WhatsApp.',
    'Your commitments often involve people — reach them without leaving the task.',
    isNew: true,
  ),
  _Card(
    'Integrity works',
    'Climb the reliability ladder.',
    'Binary scoring: done = +1, not = 0. Kept ÷ committed is your effectiveness.',
    'Example',
    'Keep 62% of your words → Professional. Push past 93% → Masterful, trusted without question.',
    'A clear, motivating path to becoming reliable.',
  ),
  _Card(
    'Value by Saara',
    'The platform earns its place.',
    'Saara scores its own work — every parse, sync, reminder, and auto-verify — so you can see what it does for you.',
    'Example',
    'A week of use → “Value by Saara · 128 pts” in your reports: captures read, results verified, syncs run.',
    'Transparent value — no black box.',
  ),
];

/// The swipeable coach flow.
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key, this.onDone});

  /// Called when the user finishes or skips (used to mark coach as seen).
  final VoidCallback? onDone;

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    widget.onDone?.call();
    if (mounted) Navigator.of(context).maybePop();
  }

  void _next() {
    if (_page >= _cards.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _cards.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(last ? '' : 'Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _cards.length,
                itemBuilder: (_, i) =>
                    _CoachCardView(card: _cards[i], index: i),
              ),
            ),
            _Dots(count: _cards.length, active: _page),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(last ? 'Get started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachCardView extends StatelessWidget {
  const _CoachCardView({required this.card, required this.index});
  final _Card card;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = card.isNew ? scheme.tertiary : scheme.primary;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${index + 1} / ${_cards.length}',
                style: TextStyle(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              if (card.isNew)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      color: scheme.onTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            card.tag.toUpperCase(),
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            card.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            card.what,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.exampleLabel.toUpperCase(),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.example,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why  ',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Expanded(
                child: Text(
                  card.why,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});
  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: on ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: on ? scheme.primary : scheme.outlineVariant,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
