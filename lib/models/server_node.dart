import 'dart:convert';

/// 服务器节点模型
class ServerNode {
  final String name;
  final String address;
  final int port;
  final String protocol; // vmess, vless, trojan, ss等
  final String? uuid;
  final String? alterId;
  final String? network; // tcp, ws, kcp等
  final String? security; // none, auto, aes-128-gcm等
  final Map<String, dynamic>? rawConfig; // 原始配置
  int? latency; // 延迟（毫秒）
  bool isSelected;

  ServerNode({
    required this.name,
    required this.address,
    required this.port,
    required this.protocol,
    this.uuid,
    this.alterId,
    this.network,
    this.security,
    this.rawConfig,
    this.latency,
    this.isSelected = false,
  });

  /// 从 Clash 配置解析节点
  factory ServerNode.fromClashConfig(Map<String, dynamic> config) {
    final type = config['type'] as String? ?? '';
    final name = config['name'] as String? ?? 'Unknown';
    final server = config['server'] as String? ?? '';
    final port = int.tryParse(config['port']?.toString() ?? '0') ?? 0;

    switch (type) {
      case 'vmess':
        // 获取 network 类型
        String networkType = 'tcp';
        if (config['network'] != null) {
          networkType = config['network'] as String;
        } else if (config['ws-opts'] != null) {
          networkType = 'ws';
        }
        
        // 获取 security/cipher
        String securityType = config['cipher'] as String? ?? 
                             config['security'] as String? ?? 
                             'auto';
        
        return ServerNode(
          name: name,
          address: server,
          port: port,
          protocol: 'vmess',
          uuid: config['uuid'] as String?,
          alterId: config['alterId']?.toString() ?? '0',
          network: networkType,
          security: securityType,
          rawConfig: {
            ...config,
            // 处理 Clash 格式的 WebSocket 配置
            if (config['ws-opts'] != null) 
              'path': (config['ws-opts'] as Map?)?['path'] ?? '/',
            if (config['ws-opts'] != null)
              'host': (config['ws-opts'] as Map?)?['headers']?['Host'],
            // 处理 TLS
            if (config['tls'] == true) 'tls': 'tls',
            if (config['servername'] != null) 'sni': config['servername'],
          },
        );
      case 'trojan':
        return ServerNode(
          name: name,
          address: server,
          port: port,
          protocol: 'trojan',
          uuid: config['password'] as String?, // trojan 使用 password 作为标识
          network: config['network'] as String? ?? 'tcp',
          rawConfig: {
            ...config,
            // 统一处理 sni 字段（Clash 可能使用 servername）
            'sni': config['sni'] ?? config['servername'],
          },
        );
      case 'vless':
        return ServerNode(
          name: name,
          address: server,
          port: port,
          protocol: 'vless',
          uuid: config['uuid'] as String?,
          network: config['network'] as String? ?? 'tcp',
          rawConfig: config,
        );
      case 'ss':
         return ServerNode(
           name: name,
           address: server,
           port: port,
           protocol: 'shadowsocks',
           uuid: config['password'] as String?,
           security: config['cipher'] as String?,
           rawConfig: config,
         );
      case 'hysteria2':
         return ServerNode(
           name: name,
           address: server,
           port: port,
           protocol: 'hysteria2',
           uuid: config['password'] as String?,
           network: 'udp',
           rawConfig: {
             ...config,
             'sni': config['sni'] ?? config['peer'],
           },
         );
      case 'wireguard':
         final privateKey = config['private-key'] as String? ?? config['privateKey'] as String? ?? '';
         final publicKey = config['public-key'] as String? ?? config['publicKey'] as String? ?? '';
         final reserved = config['reserved'];
         final mtu = config['mtu'] as int? ?? 1420;
         final ip = config['ip'] as String? ?? config['address'] as String? ?? '10.0.0.1/32';
         
         return ServerNode(
           name: name,
           address: server,
           port: port,
           protocol: 'wireguard',
           uuid: privateKey,
           rawConfig: {
             ...config,
             'privateKey': privateKey,
             'secretKey': privateKey,
             'publicKey': publicKey,
             'endpoint': '$server:$port',
             'address': ip,
             'mtu': mtu,
             if (reserved != null) 'reserved': reserved is List ? reserved : null,
           },
         );
      case 'tuic':
         final uuid = config['uuid'] as String? ?? '';
         final password = config['password'] as String? ?? config['token'] as String? ?? '';
         final congestionControl = config['congestion-controller'] as String? ?? 
                                   config['congestion_control'] as String? ?? 'cubic';
         final udpRelayMode = config['udp-relay-mode'] as String? ?? 
                              config['udp_relay_mode'] as String? ?? 'native';
         final alpn = config['alpn'];
         final sni = config['sni'] as String? ?? server;
         
         return ServerNode(
           name: name,
           address: server,
           port: port,
           protocol: 'tuic',
           uuid: uuid,
           rawConfig: {
             ...config,
             'uuid': uuid,
             'password': password,
             'congestion_control': congestionControl,
             'udp_relay_mode': udpRelayMode,
             'sni': sni,
             if (alpn != null) 'alpn': alpn is List ? alpn.join(',') : alpn,
           },
         );
      default:
        // 不支持的协议类型
        return ServerNode(
          name: name,
          address: server,
          port: port,
          protocol: type,
          rawConfig: config,
        );
    }
  }

  /// 从VMess链接解析
  factory ServerNode.fromVmess(String vmessLink) {
    try {
      // vmess://base64编码的JSON
      if (!vmessLink.startsWith('vmess://')) {
        throw Exception('Invalid VMess link');
      }

      final base64Str = vmessLink.substring(8);
      final decoded = String.fromCharCodes(
        base64Decode(base64Str),
      );
      final json = jsonDecode(decoded) as Map<String, dynamic>;

      return ServerNode(
        name: json['ps'] as String? ?? 'Unknown',
        address: json['add'] as String? ?? '',
        port: int.tryParse(json['port']?.toString() ?? '0') ?? 0,
        protocol: 'vmess',
        uuid: json['id'] as String?,
        alterId: json['aid']?.toString(),
        network: json['net'] as String? ?? 'tcp',
        security: json['scy'] as String? ?? 'auto',
        rawConfig: json,
      );
    } catch (e) {
      throw Exception('Failed to parse VMess link: $e');
    }
  }

  /// 从Trojan链接解析
  static ServerNode? fromTrojan(String trojanLink) {
    try {
      // trojan://password@server:port?params
      if (!trojanLink.startsWith('trojan://')) {
        return null;
      }

      final uri = Uri.parse(trojanLink);
      final query = uri.queryParameters;
      final password = uri.userInfo;
      final server = uri.host;
      final port = uri.port;
      final network = query['type'] ?? query['network'] ?? 'tcp';
      final security = query['security'];
      final sni = query['sni'] ?? query['peer'] ?? query['host'];
      final allowInsecure = _parseBool(query['allowInsecure'] ?? query['allowinsecure']);
      final headerType = query['headerType'] ?? query['header_type'] ?? query['header'];

      return ServerNode(
        name: uri.fragment.isNotEmpty ? uri.fragment : 'Trojan',
        address: server,
        port: port,
        protocol: 'trojan',
        uuid: password, // trojan 使用 password
        network: network,
        rawConfig: {
          'password': password,
          'server': server,
          'port': port,
          if (security != null) 'security': security,
          if (sni != null) 'sni': sni,
          if (allowInsecure == true) 'allowInsecure': true,
          if (headerType != null) 'headerType': headerType,
        },
      );
    } catch (e) {
      return null;
    }
  }

  /// 从VLESS链接解析
  static ServerNode? fromVless(String vlessLink) {
    try {
      if (!vlessLink.startsWith('vless://')) {
        return null;
      }

      final uri = Uri.parse(vlessLink);
      final query = uri.queryParameters;
      final uuid = uri.userInfo;
      final server = uri.host;
      final port = uri.port;
      final network = query['type'] ?? query['network'] ?? 'tcp';
      final security = query['security'];
      final headerType = query['headerType'] ?? query['header_type'] ?? query['header'];
      final host = query['host'];
      final path = query['path'];
      final alpn = query['alpn'];
      final allowInsecure = _parseBool(
        query['insecure'] ?? query['allowInsecure'] ?? query['allow_insecure'],
      );

      return ServerNode(
        name: _decodeNodeName(uri.fragment, fallback: 'VLESS'),
        address: server,
        port: port,
        protocol: 'vless',
        uuid: uuid,
        network: network,
        rawConfig: {
          'uuid': uuid,
          'server': server,
          'port': port,
          if (query['encryption'] != null) 'encryption': query['encryption'],
          if (query['flow'] != null) 'flow': query['flow'],
          if (security != null) 'security': security,
          if (query['sni'] != null) 'sni': query['sni'],
          if (query['fp'] != null) 'fp': query['fp'],
          if (query['pbk'] != null) 'pbk': query['pbk'],
          if (query['sid'] != null) 'sid': query['sid'],
          if (query['spx'] != null) 'spx': query['spx'],
          if (allowInsecure != null) 'allowInsecure': allowInsecure,
          if (headerType != null && headerType.isNotEmpty) 'headerType': headerType,
          if (host != null && host.isNotEmpty) 'host': host,
          if (path != null && path.isNotEmpty) 'path': path,
          if (alpn != null && alpn.isNotEmpty) 'alpn': alpn,
        },
      );
    } catch (e) {
      return null;
    }
  }

  /// 从 Shadowsocks 链接解析
  static ServerNode? fromShadowsocks(String ssLink) {
    try {
      if (!ssLink.startsWith('ss://')) return null;

      var uri = Uri.parse(ssLink);
      String userInfo = uri.userInfo;
      
      // 处理 ss://BASE64@HOST:PORT#TAG 格式
      if (userInfo.isEmpty && uri.host.isNotEmpty && !ssLink.contains('@')) {
         // 可能是全 Base64 格式 ss://Base64(#Tag)
         String base64Str = ssLink.substring(5);
         String tag = '';
         if (base64Str.contains('#')) {
            final parts = base64Str.split('#');
            base64Str = parts[0];
            if (parts.length > 1) tag = parts[1];
         }
         
         try {
           // 补全 padding
           final padding = base64Str.length % 4;
           if (padding > 0) base64Str += '=' * (4 - padding);
           final decoded = utf8.decode(base64Decode(base64Str));
           // decoded 格式: method:password@host:port
           final lastAt = decoded.lastIndexOf('@');
           if (lastAt == -1) return null;
           
           userInfo = decoded.substring(0, lastAt);
           final addressPart = decoded.substring(lastAt + 1);
           final colonIndex = addressPart.lastIndexOf(':');
           if (colonIndex == -1) return null;
           
           final host = addressPart.substring(0, colonIndex);
           final port = int.tryParse(addressPart.substring(colonIndex + 1)) ?? 0;
           
           // 解析 user info (method:password)
           final methodPass = userInfo.split(':');
           if (methodPass.length < 2) return null;
           
           return ServerNode(
             name: _decodeNodeName(tag, fallback: 'Shadowsocks'),
             address: host,
             port: port,
             protocol: 'shadowsocks',
             uuid: methodPass.sublist(1).join(':'),
             security: methodPass[0],
             rawConfig: {
               'password': methodPass.sublist(1).join(':'),
               'method': methodPass[0],
             },
           );
         } catch (_) {
           return null;
         }
      }

      // 处理普通 URL 格式 ss://method:password@host:port#tag:
      // 如果 userInfo 是 base64 编码的 (不含 :)
      if (!userInfo.contains(':')) {
         try {
           final decodedUser = utf8.decode(base64Decode(userInfo));
           userInfo = decodedUser;
         } catch (_) {}
      }
      
      final parts = userInfo.split(':');
      if (parts.length < 2) return null;
      
      final method = parts[0];
      final password = parts.sublist(1).join(':');

      return ServerNode(
        name: _decodeNodeName(uri.fragment, fallback: 'Shadowsocks'),
        address: uri.host,
        port: uri.port,
        protocol: 'shadowsocks',
        uuid: password,
        security: method,
        rawConfig: {
          'password': password,
          'method': method,
        },
      );
    } catch (e) {
      return null;
    }
  }

  /// 从 Hysteria2 链接解析
  static ServerNode? fromHysteria2(String link) {
    try {
      if (!link.startsWith('hysteria2://') && !link.startsWith('hy2://')) {
        return null; 
      }

      final uri = Uri.parse(link);
      final query = uri.queryParameters;
      
      // hy2://password@host:port
      final password = uri.userInfo;
      final server = uri.host;
      final port = uri.port;
      
      final sni = query['peer'] ?? query['sni'];
      final insecure = _parseBool(query['insecure'] ?? query['allowInsecure']);
      final obfs = query['obfs'];
      final obfsPassword = query['obfs-password'];

      return ServerNode(
        name: _decodeNodeName(uri.fragment, fallback: 'Hysteria2'),
        address: server,
        port: port,
        protocol: 'hysteria2',
        uuid: password,
        network: 'udp',
        rawConfig: {
          'password': password,
          'auth': password,
          'server': server,
          'port': port,
          if (sni != null) 'sni': sni,
          if (insecure != null) 'allowInsecure': insecure,
          if (obfs != null) 'obfs': obfs,
          if (obfsPassword != null) 'obfs-password': obfsPassword,
        },
      );
    } catch (e) {
      return null;
    }
  }

  /// 从 WireGuard 链接解析
  /// 格式: wireguard://privateKey@endpoint:port?publicKey=xxx&address=10.0.0.1/32&mtu=1420&reserved=1,2,3#名称
  /// 或: wg://...
  static ServerNode? fromWireGuard(String link) {
    try {
      if (!link.startsWith('wireguard://') && !link.startsWith('wg://')) {
        return null;
      }

      final uri = Uri.parse(link);
      final query = uri.queryParameters;
      
      final privateKey = uri.userInfo;
      final endpoint = uri.host;
      final port = uri.port > 0 ? uri.port : 51820;
      
      final publicKey = query['publicKey'] ?? query['public_key'] ?? query['peer'];
      final address = query['address'] ?? query['ip'] ?? '10.0.0.1/32';
      final mtu = int.tryParse(query['mtu'] ?? '1420') ?? 1420;
      
      // reserved 可能是 "1,2,3" 格式
      List<int>? reserved;
      final reservedStr = query['reserved'];
      if (reservedStr != null && reservedStr.isNotEmpty) {
        reserved = reservedStr.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
      }

      return ServerNode(
        name: _decodeNodeName(uri.fragment, fallback: 'WireGuard'),
        address: endpoint,
        port: port,
        protocol: 'wireguard',
        uuid: privateKey, // 用 uuid 存储 privateKey
        rawConfig: {
          'privateKey': privateKey,
          'secretKey': privateKey,
          'publicKey': publicKey,
          'endpoint': '$endpoint:$port',
          'address': address,
          'mtu': mtu,
          if (reserved != null) 'reserved': reserved,
          if (query['allowedIPs'] != null) 'allowedIPs': query['allowedIPs'],
          if (query['keepAlive'] != null) 'keepAlive': int.tryParse(query['keepAlive']!) ?? 0,
        },
      );
    } catch (e) {
      return null;
    }
  }

  /// 从 TUIC 链接解析
  /// 格式: tuic://uuid:password@host:port?congestion_control=cubic&alpn=h3&sni=example.com&udp_relay_mode=native#名称
  static ServerNode? fromTuic(String link) {
    try {
      if (!link.startsWith('tuic://')) {
        return null;
      }

      final uri = Uri.parse(link);
      final query = uri.queryParameters;
      
      // userInfo 格式: uuid:password
      final userInfoParts = uri.userInfo.split(':');
      final uuid = userInfoParts.isNotEmpty ? userInfoParts[0] : '';
      final password = userInfoParts.length > 1 ? userInfoParts.sublist(1).join(':') : '';
      
      final server = uri.host;
      final port = uri.port > 0 ? uri.port : 443;
      
      final congestionControl = query['congestion_control'] ?? query['cc'] ?? 'cubic';
      final alpn = query['alpn'] ?? 'h3';
      final sni = query['sni'] ?? query['peer'] ?? server;
      final udpRelayMode = query['udp_relay_mode'] ?? query['udp'] ?? 'native';
      final allowInsecure = _parseBool(query['allow_insecure'] ?? query['insecure'] ?? query['allowInsecure']);
      final disableSni = _parseBool(query['disable_sni']);

      return ServerNode(
        name: _decodeNodeName(uri.fragment, fallback: 'TUIC'),
        address: server,
        port: port,
        protocol: 'tuic',
        uuid: uuid,
        rawConfig: {
          'uuid': uuid,
          'password': password,
          'server': server,
          'port': port,
          'congestion_control': congestionControl,
          'alpn': alpn,
          'sni': sni,
          'udp_relay_mode': udpRelayMode,
          if (allowInsecure != null) 'allowInsecure': allowInsecure,
          if (disableSni != null) 'disable_sni': disableSni,
        },
      );
    } catch (e) {
      return null;
    }
  }

  /// 智能解析订阅内容
  static List<ServerNode> parseFromContent(String content) {
    if (content.isEmpty) return [];

    var decodedContent = content;
    // 简单判断是否 Base64
    if (!content.contains('://')) {
      try {
        final clean = content.trim().replaceAll(RegExp(r'\s+'), '');
        final padding = clean.length % 4;
        final padded = padding > 0 ? clean + '=' * (4 - padding) : clean;
        final decoded = utf8.decode(base64Decode(padded));
        // 如果解码后看起来像是有协议头的，或者多行内容
        if (decoded.contains('://') || decoded.contains('\n')) {
          decodedContent = decoded;
        }
      } catch (_) {
        // 解码失败，假设不是 Base64，继续尝试直接解析
      }
    }

    final nodes = <ServerNode>[];
    final lines = LineSplitter.split(decodedContent);

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      try {
        if (line.startsWith('vmess://')) {
          nodes.add(ServerNode.fromVmess(line));
        } else if (line.startsWith('vless://')) {
          final node = ServerNode.fromVless(line);
          if (node != null) nodes.add(node);
        } else if (line.startsWith('trojan://')) {
          final node = ServerNode.fromTrojan(line);
          if (node != null) nodes.add(node);
        } else if (line.startsWith('ss://')) {
          final node = ServerNode.fromShadowsocks(line);
          if (node != null) nodes.add(node);
        } else if (line.startsWith('hysteria2://') || line.startsWith('hy2://')) {
           final node = ServerNode.fromHysteria2(line);
           if (node != null) nodes.add(node);
        } else if (line.startsWith('wireguard://') || line.startsWith('wg://')) {
           final node = ServerNode.fromWireGuard(line);
           if (node != null) nodes.add(node);
        } else if (line.startsWith('tuic://')) {
           final node = ServerNode.fromTuic(line);
           if (node != null) nodes.add(node);
        }
      } catch (_) {
        // 忽略单行解析错误
      }
    }
    return nodes;
  }

  static String _decodeNodeName(String fragment, {required String fallback}) {
    if (fragment.isEmpty) return fallback;
    try {
      return Uri.decodeComponent(fragment);
    } catch (e) {
      return fragment;
    }
  }

  /// 转换为V2ray配置JSON（返回outbound配置）
  Map<String, dynamic> toV2rayConfig() {
    if (protocol == 'vmess') {
      final outbound = <String, dynamic>{
        'protocol': 'vmess',
        'settings': {
          'vnext': [
            {
              'address': address,
              'port': port,
              'users': [
                {
                  'id': uuid ?? '',
                  'alterId': int.tryParse(alterId ?? '0') ?? 0,
                  'security': security ?? 'auto',
                }
              ]
            }
          ]
        },
      };

      // 添加streamSettings
      final streamSettings = <String, dynamic>{
        'network': network ?? 'tcp',
      };

      // WebSocket配置
      if (network == 'ws') {
        streamSettings['wsSettings'] = {
          'path': rawConfig?['path'] ?? '/',
          if (rawConfig?['host'] != null) 'headers': {
            'Host': rawConfig!['host'],
          },
        };
      }

      // TLS配置
      if (rawConfig?['tls'] != null && rawConfig!['tls'] == 'tls') {
        streamSettings['security'] = 'tls';
        if (rawConfig?['sni'] != null) {
          streamSettings['tlsSettings'] = {
            'serverName': rawConfig!['sni'],
          };
        }
      }

      outbound['streamSettings'] = streamSettings;
      return outbound;
    } else if (protocol == 'trojan') {
      // Trojan 协议配置
      final outbound = <String, dynamic>{
        'protocol': 'trojan',
        'settings': {
          'servers': [
            {
              'address': address,
              'port': port,
              'password': uuid ?? '',
            }
          ]
        },
      };

      // 添加 streamSettings
      final streamSettings = <String, dynamic>{
        'network': network ?? 'tcp',
      };

      // TLS 配置（Trojan 默认使用 TLS）
      streamSettings['security'] = 'tls';
      final sni = rawConfig?['sni'] as String?;
      final skipCertVerify = rawConfig?['skip-cert-verify'] == true ||
          rawConfig?['allowInsecure'] == true;
      
      if (sni != null || skipCertVerify) {
        streamSettings['tlsSettings'] = <String, dynamic>{
          if (sni != null) 'serverName': sni,
          if (skipCertVerify) 'allowInsecure': true,
        };
      }

      final headerType = rawConfig?['headerType'] as String?;
      if ((network ?? 'tcp') == 'tcp' && headerType != null) {
        streamSettings['tcpSettings'] = <String, dynamic>{
          'header': <String, dynamic>{
            'type': headerType,
          },
        };
      }

      outbound['streamSettings'] = streamSettings;
      return outbound;
    } else if (protocol == 'vless') {
      // VLESS 协议配置
      final outbound = <String, dynamic>{
        'protocol': 'vless',
        'settings': {
          'vnext': [
            {
              'address': address,
              'port': port,
              'users': [
                {
                  'id': uuid ?? '',
                  'encryption': rawConfig?['encryption'] ?? 'none',
                  if (rawConfig?['flow'] != null) 'flow': rawConfig!['flow'],
                }
              ]
            }
          ]
        },
      };

      // 添加 streamSettings
      final streamSettings = <String, dynamic>{
        'network': network ?? 'tcp',
      };

      final security = rawConfig?['security'] as String?;
      final headerType = rawConfig?['headerType'] as String?;
      final host = rawConfig?['host'] as String?;
      final path = rawConfig?['path'] as String?;

      if ((network ?? 'tcp') == 'tcp') {
        if (headerType == 'http') {
          streamSettings['tcpSettings'] = <String, dynamic>{
            'header': <String, dynamic>{
              'type': 'http',
              'request': <String, dynamic>{
                if (host != null && host.isNotEmpty)
                  'headers': <String, dynamic>{
                    'Host': host.split(',').map((value) => value.trim()).where((value) => value.isNotEmpty).toList(),
                  },
                if (path != null && path.isNotEmpty)
                  'path': path.split(',').map((value) => value.trim()).where((value) => value.isNotEmpty).toList(),
              },
            },
          };
        } else {
          streamSettings['tcpSettings'] = <String, dynamic>{
            'header': <String, dynamic>{
              'type': 'none',
            },
          };
        }
      }

      // TLS / REALITY 配置
      if (security == 'reality') {
        final sni = (rawConfig?['sni'] as String?)?.isNotEmpty == true
            ? rawConfig!['sni'] as String
            : host;
        final allowInsecure = rawConfig?['allowInsecure'] == true;
        streamSettings['security'] = 'reality';
        streamSettings['realitySettings'] = <String, dynamic>{
          if (sni != null && sni.isNotEmpty) 'serverName': sni,
          if (rawConfig?['fp'] != null) 'fingerprint': rawConfig!['fp'],
          if (rawConfig?['pbk'] != null) 'publicKey': rawConfig!['pbk'],
          if (rawConfig?['sid'] != null) 'shortId': rawConfig!['sid'],
          if (rawConfig?['spx'] != null) 'spiderX': rawConfig!['spx'],
          'allowInsecure': allowInsecure,
          'show': false,
          if (rawConfig?['alpn'] != null)
            'alpn': (rawConfig!['alpn'] as String)
                .split(',')
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList(),
        };
      } else if (rawConfig?['tls'] == true ||
          rawConfig?['tls'] == 'tls' ||
          security == 'tls') {
        streamSettings['security'] = 'tls';
        if (rawConfig?['sni'] != null) {
          streamSettings['tlsSettings'] = {
            'serverName': rawConfig!['sni'],
          };
        }
      }

      outbound['streamSettings'] = streamSettings;
      return outbound;
    } else if (protocol == 'shadowsocks') {
      // Shadowsocks 协议配置
      final outbound = <String, dynamic>{
        'protocol': 'shadowsocks',
        'settings': {
          'servers': [
            {
              'address': address,
              'port': port,
              'password': uuid ?? '',
              'method': security ?? 'aes-128-gcm',
              'uot': true,
            }
          ]
        },
      };
      return outbound;
    } else if (protocol == 'hysteria2') {
      // Hysteria2 协议配置
      final sni = rawConfig?['sni'] as String?;
      final allowInsecure = rawConfig?['skip-cert-verify'] == true ||
          rawConfig?['allowInsecure'] == true ||
          rawConfig?['insecure'] == true;
      final obfsType = rawConfig?['obfs'] ?? rawConfig?['obfs-type'];
      final obfsPassword =
          rawConfig?['obfs-password'] ?? rawConfig?['obfsPassword'];

      final outbound = <String, dynamic>{
        'protocol': 'hysteria2',
        'settings': {
          'servers': [
            {
              'address': address,
              'port': port,
              'auth': uuid ?? '',
              if (sni != null || allowInsecure)
                'tls': {
                  if (sni != null) 'sni': sni,
                  if (allowInsecure) 'insecure': true,
                },
              if (obfsType != null || obfsPassword != null)
                'obfs': {
                  'type': (obfsType ?? 'salamander').toString(),
                  if (obfsPassword != null &&
                      obfsPassword.toString().isNotEmpty)
                    'password': obfsPassword,
                },
            }
          ]
        },
      };
      return outbound;
    } else if (protocol == 'wireguard') {
      // WireGuard 协议配置
      final secretKey = rawConfig?['secretKey'] ?? rawConfig?['privateKey'] ?? uuid ?? '';
      final publicKey = rawConfig?['publicKey'] ?? '';
      final addressList = <String>[];
      final addrConfig = rawConfig?['address'];
      if (addrConfig is String) {
        addressList.add(addrConfig);
      } else if (addrConfig is List) {
        addressList.addAll(addrConfig.map((e) => e.toString()));
      } else {
        addressList.add('10.0.0.1/32');
      }
      
      final mtu = rawConfig?['mtu'] as int? ?? 1420;
      final reserved = rawConfig?['reserved'];
      final keepAlive = rawConfig?['keepAlive'] as int? ?? 0;
      
      final outbound = <String, dynamic>{
        'protocol': 'wireguard',
        'settings': {
          'secretKey': secretKey,
          'address': addressList,
          'peers': [
            {
              'endpoint': '$address:$port',
              'publicKey': publicKey,
              if (keepAlive > 0) 'keepAlive': keepAlive,
            }
          ],
          'mtu': mtu,
          if (reserved is List) 'reserved': reserved,
        },
      };
      return outbound;
    } else if (protocol == 'tuic') {
      // TUIC 协议配置
      final tuicUuid = rawConfig?['uuid'] ?? uuid ?? '';
      final password = rawConfig?['password'] ?? '';
      final congestionControl = rawConfig?['congestion_control'] ?? 'cubic';
      final udpRelayMode = rawConfig?['udp_relay_mode'] ?? 'native';
      final sni = rawConfig?['sni'] as String? ?? address;
      final alpnStr = rawConfig?['alpn'] as String? ?? 'h3';
      final alpn = alpnStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final allowInsecure = rawConfig?['allowInsecure'] == true;
      
      final outbound = <String, dynamic>{
        'protocol': 'tuic',
        'settings': {
          'servers': [
            {
              'address': address,
              'port': port,
              'uuid': tuicUuid,
              'password': password,
              'congestion_control': congestionControl,
              'udp_relay_mode': udpRelayMode,
            }
          ]
        },
      };
      
      final streamSettings = <String, dynamic>{
        'security': 'tls',
        'tlsSettings': {
          'serverName': sni,
          'alpn': alpn,
          if (allowInsecure) 'allowInsecure': true,
        },
      };
      
      outbound['streamSettings'] = streamSettings;
      return outbound;
    }
    // 不支持的协议
    return {};
  }

  @override
  String toString() => '$name ($address:$port)';
}

bool? _parseBool(String? value) {
  if (value == null) return null;
  switch (value.toLowerCase()) {
    case '1':
    case 'true':
    case 'yes':
    case 'on':
      return true;
    case '0':
    case 'false':
    case 'no':
    case 'off':
      return false;
    default:
      return null;
  }
}
