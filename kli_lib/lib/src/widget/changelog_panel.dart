import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:kli_lib/src/global.dart';
import 'package:url_launcher/url_launcher.dart';

class ChangelogPanel extends StatelessWidget {
  final String changelog;

  const ChangelogPanel(this.changelog, {super.key});

  @override
  Widget build(BuildContext context) {
    late final List<String> split;
    split = changelog.split(RegExp("(?={)|(?<=})"));
    return SingleChildScrollView(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: fontSizeMSmall),
          children: <InlineSpan>[
            for (String t in split)
              TextSpan(
                text: t.startsWith('{') ? t.substring(1, t.length - 1) : t,
                style: t.startsWith('{') ? const TextStyle(color: Colors.blue) : null,
                recognizer: t.startsWith('{')
                    ? (TapGestureRecognizer()
                      ..onTap = () {
                        logMessageController.add((LogType.info, 'Opening commit: $t'));
                        final commitID = t.replaceAll(RegExp(r'(latest)|[{}]'), '');
                        final url = 'https://github.com/Bill-GD/kim_lien_intelligence/commit/$commitID';
                        launchUrl(Uri.parse(url));
                      })
                    : null,
              )
          ],
        ),
        softWrap: true,
      ),
    );
  }
}
