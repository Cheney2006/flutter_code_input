import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// @desc: 验证码输入
/// @author: cy
/// @time: 2019-05-16 10:47:55
typedef GetSmsCode = Function();

/// Default text style of displaying pin
const TextStyle defaultStyle = TextStyle(
  /// Default text color.
  color: const Color(0xff10BFC7),

  /// Default text size.
  fontSize: 24.0,
);

abstract class CodeDecoration {
  /// The style of painting text.
  final TextStyle textStyle;

  final ObscureStyle obscureStyle;

  const CodeDecoration({
    this.textStyle,
    this.obscureStyle,
  });
}

/// The object determine the obscure display
class ObscureStyle {
  /// Determine whether replace [obscureText] with number.
  final bool isTextObscure;

  /// The display text when [isTextObscure] is true
  final String obscureText;

  const ObscureStyle({
    this.isTextObscure: false,
    this.obscureText: '*',
  }) : assert(obscureText.length == 1);
}

/// The object determine the underline color etc.
class UnderlineDecoration extends CodeDecoration {
  /// The space between text and underline.
  final double gapSpace;

  /// The color of the underline.
  final Color color;

  /// The height of the underline.
  final double lineHeight;

  /// The underline changed color when user enter pin.
  final Color enteredColor;

  const UnderlineDecoration({
    TextStyle textStyle,
    ObscureStyle obscureStyle,
    this.enteredColor: const Color(0xff10BFC7),
    this.gapSpace: 16.0,
    this.color: const Color(0xff666666),
    this.lineHeight: 1.0,
  }) : super(
          textStyle: textStyle,
          obscureStyle: obscureStyle,
        );
}

class CodeInputTextField extends StatefulWidget {
  /// The max length of pin.
  final int codeLength;

  /// The callback will execute when user click done.
  final ValueChanged<String> onSubmit;

  /// Decorate the pin.
  final CodeDecoration decoration;

  /// Just like [TextField]'s inputFormatter.
  final List<TextInputFormatter> inputFormatters;

  /// Just like [TextField]'s keyboardType.
  final TextInputType keyboardType;

  /// Same as [TextField]'s autoFocus.
  final bool autoFocus;

  /// Same as [TextField]'s focusNode.
  final FocusNode focusNode;

  /// Same as [TextField]'s textInputAction.
  final TextInputAction textInputAction;

  ///倒计时总数
  final int countdown;

  ///方法回调Function，或者通知 EventBus 通信
  final GetSmsCode getSmsCode;

  CodeInputTextField({
    this.codeLength: 6,
    this.onSubmit,
    this.decoration: const UnderlineDecoration(),
    List<TextInputFormatter> inputFormatter,
    this.keyboardType: TextInputType.number,
    this.focusNode,
    this.autoFocus = false,
    this.textInputAction = TextInputAction.done,
    this.countdown = 60,
    this.getSmsCode,
  }) : inputFormatters = inputFormatter ??
            <TextInputFormatter>[WhitelistingTextInputFormatter.digitsOnly];

  @override
  State createState() {
    return _CodeInputTextFieldState();
  }
}

class _CodeInputTextFieldState extends State<CodeInputTextField>
    with SingleTickerProviderStateMixin {
  ///输入监听器
  TextEditingController _controller = TextEditingController();

  /// The display text to the user.
  String _text;

  /// 倒计时的计时器
  Timer _timer;

  ///倒计时秒
  int _seconds;

  ///按钮文案
  String _codeStr = '获取验证码';

  ///倒计时文案
  String _countStr = '';

  AnimationController _animationController;
  Animation<double> _animation;

  @override
  void initState() {
    _controller.addListener(() {
      setState(() {
        _text = _controller.text;
      });
      if (_controller.text.length >= widget.codeLength) {
        widget.onSubmit(_controller.text.substring(0, widget.codeLength));
      }
    });

    _animationController =
        AnimationController(duration: Duration(milliseconds: 500), vsync: this);

    _animation = Tween(begin: 0.0, end: 255.0).animate(_animationController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          //动画执行结束时反向执行动画
          _animationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          //动画恢复到初始状态时执行动画（正向）
          _animationController.forward();
        }
      })
      ..addListener(() {
        setState(() {});
      });

    ///启动动画
    _animationController.forward();

    initCodeBtn();
    super.initState();
  }

  Future<Null> initCodeBtn() async {
    await new Future.delayed(new Duration(seconds: 1));
    _codeBtnClick();
    return null;
  }

  @override
  void dispose() {
    /// Only execute when the controller is autoDispose.
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      /// The foreground paint to display pin.
      foregroundPainter: _CodePaint(
          text: _text,
          codeLength: widget.codeLength,
          decoration: widget.decoration,
          cursorAlpha: _animation.value.toInt(),
          cursorAnimationListener: (bool isStart) {
            if (!_animationController.isAnimating && isStart) {
              _animationController.addListener(() {
                setState(() {});
              });
            } else {
              _animationController.removeListener(() {});
            }
          }),
      child: RepaintBoundary(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            /// Actual textEditingController.
            controller: _controller,

            /// Fake the text style.
            style: TextStyle(
              /// Hide the editing text.
              color: Colors.transparent,
            ),

            /// Hide the Cursor.
            cursorColor: Colors.transparent,

            /// Hide the cursor.
            cursorWidth: 0.0,

            /// No need to correct the user input.
            autocorrect: false,

            /// Center the input to make more natrual.
            textAlign: TextAlign.center,

            /// Disable the actual textField selection.
            enableInteractiveSelection: false,

            /// The maxLength of the pin input, the default value is 6.
            maxLength: widget.codeLength,

            /// If use system keyboard and user click done, it will execute callback
            /// Note!!! Custom keyboard in Android will not execute, see the related issue [https://github.com/flutter/flutter/issues/19027]
            onSubmitted: widget.onSubmit,

            /// Default text input type is number.
            keyboardType: widget.keyboardType,

            /// only accept digits.
            inputFormatters: widget.inputFormatters,

            /// Defines the keyboard focus for this widget.
            focusNode: widget.focusNode,

            /// {@macro flutter.widgets.editableText.autofocus}
            autofocus: widget.autoFocus,

            /// The type of action button to use for the keyboard.
            ///
            /// Defaults to [TextInputAction.done]
            textInputAction: widget.textInputAction,

            /// {@macro flutter.widgets.editableText.obscureText}
            /// Default value of the obscureText is false. Make
            obscureText: true,

            /// Clear default text decoration.
            decoration: InputDecoration(
              /// Hide the counterText
              counterText: '',

              /// Hide the outline border.
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
            ),
          ),
          GestureDetector(
            child: Container(
              margin: EdgeInsets.only(top: 16.0),
              child: RichText(
                text: TextSpan(
                    text: _codeStr,
                    style: TextStyle(
                      color: Color(0xff10BFC7),
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                          text: _countStr,
                          style: TextStyle(
                            color: Color(0xff999999),
                            fontSize: 14,
                          )),
                    ]),
              ),
            ),
            onTap: () => _codeBtnClick(),
          ),
        ]),
      ),
    );
  }

  void _codeBtnClick() {
    _seconds = widget.countdown;
    if (_timer == null || !_timer.isActive) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        _seconds--;
        _codeStr = '${_seconds}s';
        _countStr = ' 后重发';
        if (_seconds <= 0) {
          ///取消倒计时
          _timer?.cancel();
          _codeStr = '重发验证码';
          _countStr = '';
        }
//        setState(() {});
      });

      if (widget.getSmsCode != null) {
        widget.getSmsCode();
      }
    }
  }
}

typedef CursorAnimationListener = Function(bool isStart);

class _CodePaint extends CustomPainter {
  String text;
  final int codeLength;
  final double space;
  final CodeDecoration decoration;
  final int cursorAlpha;
  final CursorAnimationListener cursorAnimationListener;

  _CodePaint({
    @required String text,
    @required this.codeLength,
    this.decoration,
    this.space: 4.0,
    this.cursorAlpha,
    this.cursorAnimationListener,
  }) {
    text ??= "";
    this.text = text.trim();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) =>
      !(oldDelegate is _CodePaint && oldDelegate.text == this.text);

  _drawUnderLine(Canvas canvas, Size size) {
    /// Force convert to [UnderlineDecoration].
    var dr = decoration as UnderlineDecoration;
    Paint underlinePaint = Paint()
      ..color = dr.color
      ..strokeWidth = dr.lineHeight
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    var startX = 0.0;
    var startY = size.height - 28.0;

    /// Calculate the width of each underline.
    double singleWidth =
        (size.width - (codeLength - 1) * dr.gapSpace) / codeLength;

    for (int i = 0; i < codeLength; i++) {
      if (i < text.length && dr.enteredColor != null) {
        underlinePaint.color = dr.enteredColor;
      } else {
        underlinePaint.color = dr.color;
      }
      canvas.drawLine(Offset(startX, startY),
          Offset(startX + singleWidth, startY), underlinePaint);
      startX += singleWidth + dr.gapSpace;
    }

    /// The char index of the [text]
    var index = 0;
    startX = 0.0;
    startY = 28.0;

    /// Determine whether display obscureText.
    bool obscureOn;
    obscureOn = decoration.obscureStyle != null &&
        decoration.obscureStyle.isTextObscure;

    /// The text style of pin.
    TextStyle textStyle;
    if (decoration.textStyle == null) {
      textStyle = defaultStyle;
    } else {
      textStyle = decoration.textStyle;
    }

    text.runes.forEach((rune) {
      String code;
      if (obscureOn) {
        code = decoration.obscureStyle.obscureText;
      } else {
        code = String.fromCharCode(rune);
      }
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          style: textStyle,
          text: code,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      /// Layout the text.
      textPainter.layout();

      startX = singleWidth * index +
          singleWidth / 2 -
          textPainter.width / 2 +
          dr.gapSpace * index;
      textPainter.paint(canvas, Offset(startX, startY));
      index++;
    });

    ///画光标
    if (text.length < codeLength) {
      Color cursorColor = Color(0xff10BFC7);
      cursorColor = cursorColor.withAlpha(cursorAlpha);

      Paint cursorPaint = Paint()
        ..color = cursorColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      startX = text.length * (singleWidth + dr.gapSpace) + singleWidth / 2;
      var endY = size.height - 28.0 - 8;
      canvas.drawLine(
          Offset(startX, startY), Offset(startX, endY), cursorPaint);
      if (cursorAnimationListener != null) {
        cursorAnimationListener(true);
      }
    } else {
      if (cursorAnimationListener != null) {
        cursorAnimationListener(false);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawUnderLine(canvas, size);
  }
}
