import "package:flutter/material.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import 'package:markdown/src/ast.dart' as md;
import "./styles.dart";

final hStyle = TextStyle(
  fontFamily: "NotoSerif",
  fontSize: 20,
  letterSpacing: 0.5,
  // color: MyColors.grey,
);

final stylehseet = MarkdownStyleSheet(
  p: TextStyle(
    fontFamily: "NotoSerif",
    fontVariations: [
      FontVariation("wght", 300),
    ],
    height: 1.75,
    fontSize: 16,
    fontWeight: FontWeight.w100,
  ),
  a: TextStyle(
    color: MyColors.a,
  ),
  strong: TextStyle(
    fontVariations: [
      FontVariation("wght", 500),
    ],
  ),
  h1: hStyle,
  h2: hStyle,
  h3: hStyle,
  h4: hStyle,
  h5: hStyle,
  h6: hStyle,
  pPadding: EdgeInsets.only(
    left: 20,
  ),
  // listBulletPadding: EdgeInsets.only(
  //   left: 10,
  // ),
  listBullet: TextStyle(
    // color: MyColors.grey,
    fontVariations: [
      FontVariation("wght", 700),
    ],
  ),
  horizontalRuleDecoration: BoxDecoration(
    border: Border.all(
      width: 0.5,
      color: MyColors.dark_txt.withValues(alpha: 0.25),
    ),
  ),
  blockSpacing: 20,
);
