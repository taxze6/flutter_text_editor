import 'package:flutter/material.dart';

class RichTextColor {
  static const defaultTextColor = Color(0xFF000000);

  static const c_FF0000 = Color(0xFFFF0000);
  static const c_000000 = Color(0xFF000000);
  static const c_5496EB = Color(0xFF5496EB);
  static const c_19FFF7 = Color(0xFF19FFF7);
  static const c_F4511E = Color(0xFFF4511E);
  static const c_C0CA33 = Color(0xFFC0CA33);

  ///用户自定义颜色解析
  Color stringToColor(String s) {
    if (s.startsWith('rgba')) {
      s = s.substring(5); //取rgba( 五个字符
      s = s.substring(0, s.length - 1); //取出剩下的字符，并覆盖
      final arr = s.split(',').map((e) => e.trim()).toList(); //根据","分割出参数
      return Color.fromRGBO(int.parse(arr[0]), int.parse(arr[1]),
          int.parse(arr[2]), double.parse(arr[3])); //返回Color值
    } else if (s.startsWith('#')) {
      s = s.toUpperCase().replaceAll("#", ""); //将字符串转为大写，同时将#号去掉
      if (s.length == 6) {
        //判断是否为正确的颜色格式
        s = "FF$s";
      }
      return Color(
          int.parse(s, radix: 16)); //返回Color值，radix:默认基数10进制，我们需要指定是16进制
    }
    return const Color.fromRGBO(0, 0, 0, 0);
  }
}
