import "package:flutter/material.dart";
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/gruvbox-dark.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/src/ast.dart' as md;

class MyHighLightBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    var lang = 'plaintext';
    final pattern = RegExp(r'^language-(.+)$');

    var className = element.attributes['class'];

    if (className != null) {
      var out = pattern.firstMatch(className)?.group(1);

      if (out != null) {
        lang = out;
      }
    }

    return HighlightView(
      element.textContent.trim(),
      language: lang,
      theme: gruvboxDarkTheme,
      textStyle: GoogleFonts.dmMono(),
      tabSize: 4,
      padding: EdgeInsets.all(10),
    );
  }
}
