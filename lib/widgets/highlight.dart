import 'package:app/styles.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/gruvbox-dark.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/src/ast.dart' as md;

class MyHighLightBuilder extends MarkdownElementBuilder {
  static final _theme = Map<String, TextStyle>.from(gruvboxDarkTheme)
    ..['root'] = gruvboxDarkTheme['root']!.copyWith(
      backgroundColor: Colors.white.withOpacity(0.05),
      color: MyColors.txt,
    );

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    var className = element.attributes['class'];

    if (className == null && !element.textContent.trim().contains('\n')) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(element.textContent.trim()),
      );
    } else {
      var lang = 'plaintext';
      final pattern = RegExp(r'^language-(.+)$');

      if (className != null) {
        var out = pattern.firstMatch(className)?.group(1);

        if (out != null) {
          lang = out;
        }
      }

      final code = element.textContent.trim();

      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 600,
              child: HighlightView(
                code,
                language: lang,
                theme: _theme,
                textStyle: GoogleFonts.dmMono(
                  fontSize: 12,
                  height: 1.75,
                ),
                tabSize: 4,
                padding: EdgeInsets.all(10),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              child: Icon(
                Icons.copy_outlined,
                size: 16,
                color: MyColors.txt.withOpacity(0.2),
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
              },
            ),
          ),
        ],
      );
    }
  }
}
