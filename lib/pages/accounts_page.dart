import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/pages/htmanga/ht_slider_captcha.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AccountsPageLogic extends StateController {
  final _reLogin = <String, bool>{};
}

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  AccountsPageLogic get logic => StateController.find<AccountsPageLogic>();

  @override
  Widget build(BuildContext context) {
    if (PopupIndicatorWidget.maybeOf(context) != null) {
      var body = StateBuilder<AccountsPageLogic>(
        init: AccountsPageLogic(),
        builder: (logic) {
          return CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate(
                  buildContent(context).toList(),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.only(bottom: context.padding.bottom),
              )
            ],
          );
        },
      );
      return PopUpWidgetScaffold(title: "账号管理".tl, body: body);
    } else {
      return MiuixScaffold(
        content: (_) => StateBuilder<AccountsPageLogic>(
          init: AccountsPageLogic(),
          builder: (logic) {
            return SmoothCustomScrollView(
              slivers: [
                SliverAppbar(
                  title: Text("账号管理".tl),
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    buildContent(context).toList(),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.only(bottom: context.padding.bottom + 20),
                )
              ],
            );
          },
        ),
      );
    }
  }

  Iterable<Widget> buildContent(BuildContext context) sync* {
    var sources =
        ComicSource.sources.where((element) => element.account != null);
    if (sources.isEmpty) return;

    for (var element in sources) {
      final bool logged = element.isLogin;
      yield MiuixSmallTitle(element.name.tl);

      final cardChildren = <Widget>[];

      if (!logged) {
        cardChildren.add(
          MiuixArrowPreference(
            startAction: const Icon(Icons.login),
            title: "登录".tl,
            summary: "点击登录该漫画源账号".tl,
            onClick: () async {
              if (element.account!.onLogin != null) {
                await element.account!.onLogin!(context);
              }
              if (element.account!.login != null && context.mounted) {
                await context.to(
                  () => _LoginPage(
                    login: element.account!.login!,
                    loginWithSlider: element.account!.loginWithSlider,
                    registerWebsite: element.account!.registerWebsite,
                  ),
                );
                element.saveData();
              }
              logic.update();
            },
          ),
        );
      } else {
        for (var item in element.account!.infoItems) {
          if (item.builder != null) {
            cardChildren.add(item.builder!(context));
          } else {
            cardChildren.add(
              MiuixArrowPreference(
                startAction: const Icon(Icons.account_circle_outlined),
                title: item.title.tl,
                summary: item.data?.call(),
                onClick: item.onTap ?? () {},
              ),
            );
          }
        }
        if (element.account!.allowReLogin) {
          bool loading = logic._reLogin[element.key] == true;
          cardChildren.add(
            MiuixArrowPreference(
              startAction: loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: MiuixCircularProgressIndicator(strokeWidth: 2, size: 20),
                    )
                  : const Icon(Icons.refresh),
              title: "重新登录".tl,
              summary: "如果登录失效点击此处".tl,
              onClick: () async {
                if (element.data["account"] == null) {
                  showToast(message: "无数据".tl);
                  return;
                }
                logic._reLogin[element.key] = true;
                logic.update();
                final List account = element.data["account"];
                var res =
                    await element.account!.login!(account[0], account[1]);
                // 需要滑块验证时，弹窗验证后用通行证重试一次。
                if (res.error && element.account!.loginWithSlider != null) {
                  final msg = res.errorMessage ?? "";
                  if (msg.contains("滑塊") ||
                      msg.contains("滑块") ||
                      msg.contains("滑動")) {
                    if (context.mounted) {
                      final pass = await requestHtSliderPass(context);
                      if (pass != null) {
                        res = await element.account!
                            .loginWithSlider!(account[0], account[1], pass);
                      }
                    }
                  }
                }
                if (res.error) {
                  showToast(message: res.errorMessage!);
                } else {
                  showToast(message: "重新登录成功".tl);
                }
                logic._reLogin[element.key] = false;
                logic.update();
              },
            ),
          );
        }
        cardChildren.add(
          MiuixArrowPreference(
            startAction: const Icon(Icons.logout, color: Colors.red),
            title: "退出登录".tl,
            onClick: () {
              element.data["account"] = null;
              element.account?.logout();
              element.saveData();
              logic.update();
            },
          ),
        );
      }

      yield Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: MiuixCard(
          insideMargin: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: cardChildren,
          ),
        ),
      );
    }
  }

  void setClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showToast(message: "已复制".tl, icon: const Icon(Icons.check));
  }
}

class _LoginPage extends StatefulWidget {
  const _LoginPage({
    required this.login,
    this.loginWithSlider,
    this.registerWebsite,
  });

  final LoginFunction login;

  /// 需要滑块验证时使用的登录函数。
  final Future<Res<bool>> Function(String, String, String)? loginWithSlider;

  final String? registerWebsite;

  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  bool _obscure = true;

  late final MiuixExitUntilCollapsedScrollBehavior _behavior;

  @override
  void initState() {
    super.initState();
    _behavior = MiuixExitUntilCollapsedScrollBehavior();
    _usernameController.addListener(_onTextChanged);
    _passwordController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _behavior.state.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  bool get _canSubmit =>
      !_loading &&
      _usernameController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MiuixTheme.of(context).colors.background,
      child: MiuixScaffold(
        containerColor: MiuixTheme.of(context).colors.background,
        topBar: MiuixTopAppBar(color: MiuixTheme.of(context).colors.background, blurred: true, blurRadius: 50, blurTintAlpha: frostTintAlpha(context), 
          title: "登录".tl,
          scrollBehavior: _behavior,
          navigationIcon: MiuixIconButton(
            child: MiuixIcon(
              vector: MiuixIcons.os4.chevronBackward,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        content: (padding) => MiuixScrollBehaviorListener(
          behavior: _behavior,
          child: SingleChildScrollView(
            // MiuixScaffold 只处理系统栏内边距，软键盘高度需自行让位，
            // 否则聚焦密码框时会被键盘遮住。
            padding: EdgeInsets.fromLTRB(
              20,
              padding.top + 8,
              20,
              padding.bottom + MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                _buildHeader(),
                const SizedBox(height: 28),
                _buildForm(),
                const SizedBox(height: 28),
                _buildSubmitButton(),
                if (widget.registerWebsite != null) ...[
                  const SizedBox(height: 10),
                  Center(child: _buildRegisterButton()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = MiuixTheme.of(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: ShapeDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            shape: const MiuixSquircleBorder(cornerRadius: 18),
          ),
          child: Center(
            child: MiuixIcon(
              vector: MiuixIcons.os4.contactsCircle,
              size: 26,
              tint: colors.primary,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          "欢迎回来".tl,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: colors.onBackground,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "登录后即可同步收藏与阅读记录".tl,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: colors.onSurfaceVariantSummary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final colors = MiuixTheme.of(context).colors;
    return MiuixCard(
      cornerRadius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          children: [
            MiuixTextField(
              controller: _usernameController,
              focusNode: _usernameFocus,
              label: "用户名".tl,
              singleLine: true,
              insideMargin: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              leadingIcon: Padding(
                padding: const EdgeInsets.only(left: 2, right: 8),
                child: MiuixIcon(
                  vector: MiuixIcons.os4.contacts,
                  size: 18,
                  tint: colors.onSurfaceVariantSummary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            MiuixTextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              label: "密码".tl,
              singleLine: true,
              obscureText: _obscure,
              insideMargin: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_canSubmit) _login();
              },
              leadingIcon: Padding(
                padding: const EdgeInsets.only(left: 2, right: 8),
                child: MiuixIcon(
                  vector: MiuixIcons.os4.lock,
                  size: 18,
                  tint: colors.onSurfaceVariantSummary,
                ),
              ),
              trailingIcon: MiuixIconButton(
                minWidth: 36,
                minHeight: 36,
                onPressed: () {
                  setState(() => _obscure = !_obscure);
                },
                child: MiuixIcon(
                  vector: _obscure
                      ? MiuixIcons.os4.show
                      : MiuixIcons.os4.hide,
                  size: 18,
                  tint: colors.onSurfaceVariantSummary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: MiuixButton(
        onPressed: _canSubmit ? _login : null,
        enabled: _canSubmit,
        cornerRadius: 16,
        minHeight: 48,
        minWidth: double.infinity,
        insideMargin: const EdgeInsets.symmetric(vertical: 12),
        colors: MiuixButtonDefaults.buttonColorsPrimary(context),
        child: _loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MiuixCircularProgressIndicator(
                    size: 16,
                    strokeWidth: 2,
                    colors: MiuixProgressIndicatorColors(
                      foregroundColor:
                          MiuixTheme.of(context).colors.onPrimary,
                      disabledForegroundColor:
                          MiuixTheme.of(context).colors.onPrimary,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text("登录中".tl),
                ],
              )
            : Text("登录".tl),
      ),
    );
  }

  Widget _buildRegisterButton() {
    final colors = MiuixTheme.of(context).colors;
    return MiuixButton(
      onPressed: () => launchUrlString(widget.registerWebsite!),
      cornerRadius: 16,
      colors: MiuixButtonColors(
        color: Colors.transparent,
        disabledColor: Colors.transparent,
        contentColor: colors.primary,
        disabledContentColor: colors.onSurfaceVariantSummary,
      ),
      insideMargin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("没有账号？前往注册".tl),
          const SizedBox(width: 4),
          const Icon(Icons.open_in_new, size: 14),
        ],
      ),
    );
  }

  void _login() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      showToast(message: "不能为空".tl, icon: const Icon(Icons.error_outline));
      return;
    }

    setState(() => _loading = true);

    Res<bool> res = await widget.login(username, password);

    // 服务端要求先完成滑块验证时，弹窗验证后带通行证重试。
    final needSlider = HtmangaNetwork.needSliderPass(res.errorMessage) ||
        _needSlider(res.errorMessage);
    if (res.error && needSlider && widget.loginWithSlider != null) {
      if (!mounted) return;
      final pass = await requestHtSliderPass(context);
      if (!mounted) return;
      if (pass == null) {
        setState(() => _loading = false);
        showToast(
          message: "已取消验证".tl,
          icon: const Icon(Icons.info_outline),
        );
        return;
      }
      res = await widget.loginWithSlider!(username, password, pass);
    }

    if (!mounted) return;

    if (res.error) {
      setState(() => _loading = false);
      // 通行证用尽/超时等服务端提示照实反馈，避免用户以为是密码错误。
      showToast(message: res.errorMessageWithoutNull);
    } else {
      setState(() => _loading = false);
      showToast(message: "登录成功".tl, icon: const Icon(Icons.check));
      if (mounted) context.pop();
    }
  }

  /// 兜底判断：部分源的错误文案由脚本返回、措辞可能与内置源不同。
  static bool _needSlider(String? message) {
    if (message == null) return false;
    final needs = message.contains("滑塊") ||
        message.contains("滑块") ||
        message.contains("滑動") ||
        message.contains("滑动");
    return needs || (message.contains("先完成") && message.contains("驗證"));
  }
}
