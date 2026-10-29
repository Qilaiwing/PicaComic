import 'package:flutter/material.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/pages/htmanga/ht_slider_captcha.dart';
import 'package:pica_comic/pages/settings/settings_page.dart'
    show JsSourceSettingTile, SettingsPage;
import 'package:pica_comic/foundation/js_engine.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// 账号管理已并入「漫画源」设置页；保留入口兼容旧跳转。
class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPage(initialPage: 1, singlePage: true);
  }
}


/// 内置漫画源账号行（与 JS 的 [JsAccountRows] 对应），供漫画源折叠卡片复用。
class BuiltInAccountRows extends StatefulWidget {
  const BuiltInAccountRows({
    super.key,
    required this.source,
    this.onChanged,
  });

  final ComicSource source;
  final VoidCallback? onChanged;

  @override
  State<BuiltInAccountRows> createState() => _BuiltInAccountRowsState();
}

class _BuiltInAccountRowsState extends State<BuiltInAccountRows> {
  bool reLoggingIn = false;

  ComicSource get source => widget.source;

  void changed() {
    if (mounted) setState(() {});
    widget.onChanged?.call();
  }

  Future<void> login() async {
    final acc = source.account!;
    if (acc.onLogin != null) {
      await acc.onLogin!(context);
    }
    if (acc.login != null && mounted) {
      await context.to(
        () => SourceLoginPage(
          sourceName: source.name,
          login: acc.login!,
          loginWithSlider: acc.loginWithSlider,
          registerWebsite: acc.registerWebsite,
        ),
      );
      source.saveData();
    }
    changed();
  }

  Future<void> reLogin() async {
    if (reLoggingIn) return;
    if (source.data["account"] == null) {
      showToast(message: "无数据".tl);
      return;
    }
    setState(() => reLoggingIn = true);
    final List account = source.data["account"];
    var res = await source.account!.login!(account[0], account[1]);
    if (res.error && source.account!.loginWithSlider != null) {
      final msg = res.errorMessage ?? "";
      if (msg.contains("滑塊") || msg.contains("滑块") || msg.contains("滑動")) {
        if (mounted) {
          final pass = await requestHtSliderPass(context);
          if (pass != null) {
            res = await source.account!
                .loginWithSlider!(account[0], account[1], pass);
          }
        }
      }
    }
    if (res.error) {
      showToast(message: res.errorMessage!);
    } else {
      showToast(message: "登录成功".tl, icon: const Icon(Icons.check));
    }
    reLoggingIn = false;
    changed();
  }

  void logout() {
    source.data["account"] = null;
    source.account?.logout();
    source.saveData();
    changed();
  }

  @override
  Widget build(BuildContext context) {
    final logged = source.isLogin;
    final acc = source.account!;
    final children = <Widget>[];

    if (!logged) {
      children.add(
        MiuixArrowPreference(
          startAction: SizedBox.square(dimension: 24, child: Center(child: MiuixIcon(vector: MiuixIcons.os4.forward, size: 22))),
          title: "登录".tl,
          summary: "点击登录该漫画源账号".tl,
          onClick: login,
        ),
      );
    } else {
      for (var item in acc.infoItems) {
        if (item.builder != null) {
          children.add(item.builder!(context));
        } else {
          children.add(
            MiuixArrowPreference(
              startAction: SizedBox.square(dimension: 24, child: Center(child: MiuixIcon(vector: MiuixIcons.os4.contactsCircle, size: 22))),
              title: item.title.tl,
              summary: item.data?.call(),
              onClick: item.onTap ?? () {},
            ),
          );
        }
      }
      if (acc.allowReLogin) {
        children.add(
          MiuixArrowPreference(
            startAction: reLoggingIn
                ? const SizedBox.square(
                    dimension: 20,
                    child: MiuixCircularProgressIndicator(
                        strokeWidth: 2, size: 20),
                  )
                : const Icon(Icons.refresh),
            title: "重新登录".tl,
            summary: "如果登录失效点击此处".tl,
            onClick: reLogin,
          ),
        );
      }
      children.add(
        MiuixArrowPreference(
          startAction: SizedBox.square(dimension: 24, child: Center(child: MiuixIcon(vector: MiuixIcons.os4.back, size: 22, tint: Colors.red))),
          title: "退出登录".tl,
          onClick: logout,
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }
}

/// 漫画源登录页，账号管理与漫画源设置共用。
class SourceLoginPage extends StatefulWidget {
  const SourceLoginPage({
    super.key,
    required this.sourceName,
    required this.login,
    this.loginWithSlider,
    this.registerWebsite,
  });

  final String sourceName;
  final LoginFunction login;

  /// 需要滑块验证时使用的登录函数。
  final Future<Res<bool>> Function(String, String, String)? loginWithSlider;

  final String? registerWebsite;

  @override
  State<SourceLoginPage> createState() => SourceLoginPageState();
}

class SourceLoginPageState extends State<SourceLoginPage> {
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
        topBar: MiuixTopAppBar(color: MiuixTheme.of(context).colors.background, blurred: true, blurRadius: 0, blurTintAlpha: 0, 
          title: "登录".tl,
          scrollBehavior: _behavior,
          navigationIcon: MiuixIconButton(
            child: MiuixIcon(
              vector: MiuixIcons.os4.chevronBackward,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          actions: [
            AppTooltip(
              message: "漫画源".tl,
              child: MiuixIconButton(
                onPressed: () => SettingsPage.openSection(1),
                child: const Icon(Icons.extension_outlined, size: 22),
              ),
            ),
          ],
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
          "欢迎回到@name".tlParams({"name": widget.sourceName.tl}),
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
                horizontal: 18,
                vertical: 14,
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              leadingIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 10),
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
                horizontal: 18,
                vertical: 14,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_canSubmit) _login();
              },
              leadingIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 10),
                child: MiuixIcon(
                  vector: MiuixIcons.os4.lock,
                  size: 18,
                  tint: colors.onSurfaceVariantSummary,
                ),
              ),
              trailingIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: MiuixIconButton(
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
                mainAxisAlignment: MainAxisAlignment.center,
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
                  Text(
                    "登录中".tl,
                    style: TextStyle(
                      color: MiuixTheme.of(context).colors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                "登录".tl,
                style: TextStyle(
                  color: MiuixTheme.of(context).colors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
      showToast(
        message: "登录成功".tl,
        icon: const Icon(Icons.check),
      );
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

/// JS 源凭证状态：调用脚本的 account.checkStatus 校验
class _JsCredentialStatus extends StatefulWidget {
  const _JsCredentialStatus({required this.source});

  final ComicSource source;

  @override
  State<_JsCredentialStatus> createState() => _JsCredentialStatusState();
}

class _JsCredentialStatusState extends State<_JsCredentialStatus> {
  bool? valid;
  bool checking = false;

  @override
  void initState() {
    super.initState();
    check();
  }

  void check() async {
    var key = widget.source.key;
    var has = JsEngine().runCode(
            "typeof ComicSource.sources.$key.account.checkStatus === 'function'") ==
        true;
    if (!has) return;
    setState(() => checking = true);
    try {
      var res = await JsEngine()
          .runCode("ComicSource.sources.$key.account.checkStatus()");
      valid = res is Map ? res["valid"] == true : null;
    } catch (e) {
      valid = null;
    }
    if (mounted) setState(() => checking = false);
  }

  @override
  Widget build(BuildContext context) {
    var colors = MiuixTheme.of(context).colors;
    String state;
    Color color;
    if (checking) {
      state = "检查中".tl;
      color = colors.onSurfaceVariantSummary;
    } else if (valid == true) {
      state = "凭证有效".tl;
      color = Colors.green;
    } else if (valid == false) {
      state = "凭证失效".tl;
      color = colors.error;
    } else {
      state = "未校验".tl;
      color = colors.onSurfaceVariantSummary;
    }
    return MiuixBasicComponent(
      startAction: SizedBox.square(dimension: 24, child: Center(child: MiuixIcon(vector: MiuixIcons.os4.lock, size: 22))),
      title: "凭证状态".tl,
      endActions: [Text(state, style: TextStyle(color: color, fontSize: 14))],
      onClick: check,
    );
  }
}

/// JS 漫画源账号行（漫画源折叠卡片共用）：
/// 账号 → 凭证状态 → 设备信息（若脚本提供）→ 重新登录 → 退出登录；未登录时显示登录行。
class JsAccountRows extends StatefulWidget {
  const JsAccountRows({super.key, required this.source, this.onChanged});

  final ComicSource source;
  final VoidCallback? onChanged;

  static const deviceKeys = ["clear_device_info", "auto_clear_device_info"];

  @override
  State<JsAccountRows> createState() => _JsAccountRowsState();
}

class _JsAccountRowsState extends State<JsAccountRows> {
  bool reLoggingIn = false;

  ComicSource get source => widget.source;

  void changed() {
    if (mounted) setState(() {});
    widget.onChanged?.call();
  }

  Future<void> login() async {
    var acc = source.account!;
    // 网页登录：只走 onLogin，不再打开账号密码页
    if (acc.onLogin != null && acc.login == null) {
      await acc.onLogin!(context);
      source.saveData();
      changed();
      return;
    }
    if (acc.onLogin != null) await acc.onLogin!(context);
    if (acc.login != null && mounted) {
      await context.to(() => SourceLoginPage(
            sourceName: source.name,
            login: acc.login!,
            loginWithSlider: acc.loginWithSlider,
            registerWebsite: acc.registerWebsite,
          ));
      source.saveData();
    }
    changed();
  }

  Future<void> reLogin() async {
    if (reLoggingIn) return;
    var acc = source.account!;
    // 网页登录源没有保存密码，重新打开 WebView
    if (acc.login == null && acc.onLogin != null) {
      setState(() => reLoggingIn = true);
      try {
        await acc.onLogin!(context);
        source.saveData();
      } finally {
        if (mounted) setState(() => reLoggingIn = false);
      }
      changed();
      return;
    }
    setState(() => reLoggingIn = true);
    var ok = await source.reLogin();
    showToast(
        message:
            ok ? "登录成功".tl : (source.lastReLoginError ?? "登录失败".tl));
    reLoggingIn = false;
    changed();
  }

  void logout() {
    source.data["account"] = null;
    source.account?.logout();
    source.data.remove("username");
    source.saveData();
    changed();
  }

  @override
  Widget build(BuildContext context) {
    var logged = source.isLogin;
    var acc = source.account!;
    var accountData = source.data["account"];
    var username = source.data["username"]?.toString() ??
        (accountData is List && accountData.isNotEmpty
            ? accountData[0].toString()
            : null);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!logged)
          MiuixArrowPreference(
            startAction: SizedBox.square(dimension: 24, child: Center(child: MiuixIcon(vector: MiuixIcons.os4.forward, size: 22))),
            title: (acc.onLogin != null && acc.login == null)
                ? "网页登录".tl
                : "登录".tl,
            summary: (acc.onLogin != null && acc.login == null)
                ? "登录完成后自动返回".tl
                : "点击登录该漫画源账号".tl,
            onClick: login,
          )
        else ...[
          MiuixArrowPreference(
            startAction: SizedBox.square(dimension: 24, child: Center(child: MiuixIcon(vector: MiuixIcons.os4.contactsCircle, size: 22))),
            title: "账号".tl,
            summary: username,
            onClick: () {},
          ),
          _JsCredentialStatus(source: source),
        ],
        for (var key in JsAccountRows.deviceKeys)
          if (source.jsSettings[key] is Map)
            JsSourceSettingTile(
              source: source,
              settingKey: key,
              config: Map<String, dynamic>.from(source.jsSettings[key]),
              onChanged: changed,
            ),
        if (logged) ...[
          MiuixArrowPreference(
            startAction: reLoggingIn
                ? const SizedBox.square(
                    dimension: 20,
                    child: MiuixCircularProgressIndicator(
                        strokeWidth: 2, size: 20),
                  )
                : const Icon(Icons.refresh),
            title: "重新登录".tl,
            summary: "如果登录失效点击此处".tl,
            onClick: reLogin,
          ),
          MiuixArrowPreference(
            startAction: SizedBox.square(dimension: 24, child: Center(child: MiuixIcon(vector: MiuixIcons.os4.back, size: 22, tint: Colors.red))),
            title: "退出登录".tl,
            onClick: logout,
          ),
        ],
      ],
    );
  }
}
