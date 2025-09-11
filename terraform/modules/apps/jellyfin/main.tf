locals {
  ingress_annotations = {
    "cert-manager.io/cluster-issuer" = var.issuer
    "kubernetes.io/ingress.class" = var.ingress_class
    # "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
    "nginx.ingress.kubernetes.io/proxy-set-headers" = jsonencode({
      "X-Forwarded-Proto" = "https"
      "X-Forwarded-Port"  = "443"
      "X-Forwarded-Host"  = "$host"
      # "X-Forwarded-For"   = "$proxy_add_x_forwarded_for"
      # "X-Real-IP"         = "$remote_addr"
    })
  }

  values = {
    deploymentStrategy = {
      type = "Recreate"
    }
    image = {
      tag = "latest"
    }
    securityContext = {
      privileged = true
    }
    service = {
      ipFamilyPolicy = "PreferDualStack"
      ipFamilies = ["IPv6", "IPv4"]
    }
    ingress = {
      enabled = true
      className = var.ingress_class
      annotations = local.ingress_annotations
      hosts = [
        for domain in var.domains : {
          host = domain
          paths = [
            {
              path     = "/"
              pathType = "ImplementationSpecific"
            }
          ]
        }
      ]
      tls = [{
        secretName = "${var.name}-tls"
        hosts = jsondecode(jsonencode(var.domains))
      }]
    }
    nodeSelector = var.node_selectors
    podAnnotations = {
      "jellyfin.org/config-hash" = sha256(jsonencode(kubernetes_config_map.jellyfin_config.data))
    }
    persistence = {
      config = {
        enabled = true
        size = var.config_storage
        storageClass = var.storage_class
      }
      media = {
        enabled = true
        size = var.data_storage
        storageClass = var.storage_class
      }
    }
    volumes = [
      {
        name = "jellyfin-config"
        configMap = {
          name = kubernetes_config_map.jellyfin_config.metadata[0].name
        }
      }
    ]
    initContainers = [
      {
        name = "setup-jellyfin"
        image = "alpine:latest"
        command = ["/bin/sh"]
        args = ["-c", <<-EOF
          apk add --no-cache curl unzip
          
          # Create directory structure
          mkdir -p /config/config
          mkdir -p /config/plugins/configurations
          
          # Copy config files from ConfigMap to PVC if they don't exist
          if [ ! -f /config/config/system.xml ]; then
            echo "Copying system.xml..."
            cp /tmp/configs/system.xml /config/config/system.xml
          fi
          
          if [ ! -f /config/config/network.xml ]; then
            echo "Copying network.xml..."
            cp /tmp/configs/network.xml /config/config/network.xml
          fi
          
          echo "Copying SSO-Auth.xml..."
          cp /tmp/configs/SSO-Auth.xml /config/plugins/configurations/SSO-Auth.xml
          
          echo "Copying branding.xml..."
          cp /tmp/configs/branding.xml /config/config/branding.xml
          
          echo "Copying Jellyfin.Plugin.CustomJavascript.xml..."
          cp /tmp/configs/Jellyfin.Plugin.CustomJavascript.xml /config/plugins/configurations/Jellyfin.Plugin.CustomJavascript.xml
          
          echo "Copying livetv.xml..."
          cp /tmp/configs/livetv.xml /config/config/livetv.xml
          
          # Install SSO plugin if not already installed
          if [ ! -f "/config/plugins/SSO-Auth/SSO-Auth.dll" ]; then
            echo "Installing SSO-Auth plugin..."
            cd /tmp
            curl -L -o sso-auth.zip "https://github.com/9p4/jellyfin-plugin-sso/releases/download/v${var.plugin_versions.sso_auth}/sso-authentication_${var.plugin_versions.sso_auth}.zip"
            unzip -o sso-auth.zip -d /config/plugins/SSO-Auth/
            rm sso-auth.zip
          fi
          
          # Install Custom JavaScript plugin if not already installed
          mkdir -p /config/plugins/Custom-JavaScript
          if [ ! -f "/config/plugins/Custom-JavaScript/Custom-Javascript.dll" ]; then
            echo "Installing Custom JavaScript plugin..."
            cd /tmp
            curl -L -o custom-js.zip "https://github.com/johnpc/jellyfin-plugin-custom-javascript/releases/download/${var.plugin_versions.custom_js}/custom-javascript-${var.plugin_versions.custom_js}.zip"
            unzip -o custom-js.zip -d /config/plugins/Custom-JavaScript/
            rm custom-js.zip
          fi
          
          echo "Setup completed successfully"
        EOF
        ]
        volumeMounts = [
          {
            name = "config"
            mountPath = "/config"
          },
          {
            name = "jellyfin-config"
            mountPath = "/tmp/configs"
          }
        ]
      }
    ]
    jellyfin = {
      env = [
        {
          name = "JELLYFIN_PublishedServerUrl"
          value = "https://${var.domains[0]}"
        }
      ]
    }
  }
}

resource "kubernetes_config_map" "jellyfin_config" {
  metadata {
    name      = "${var.name}-config"
    namespace = var.namespace
  }
  data = {
    "system.xml" = <<-XML
      <?xml version="1.0" encoding="utf-8"?>
      <ServerConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <IsStartupWizardCompleted>false</IsStartupWizardCompleted>
        <ServerName>Jellyfin Home</ServerName>
        <PluginRepositories>
          <RepositoryInfo>
            <Name>Jellyfin Stable</Name>
            <Url>https://repo.jellyfin.org/files/plugin/manifest.json</Url>
            <Enabled>true</Enabled>
          </RepositoryInfo>
          <RepositoryInfo>
            <Name>SSO-Auth Plugin Repository</Name>
            <Url>https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json</Url>
            <Enabled>true</Enabled>
          </RepositoryInfo>
        </PluginRepositories>
        <LogFileRetentionDays>3</LogFileRetentionDays>
        <EnableMetrics>false</EnableMetrics>
        <EnableLiveTv>${var.live_tv.enabled}</EnableLiveTv>
      </ServerConfiguration>
    XML
    
    "network.xml" = <<-XML
      <?xml version="1.0" encoding="utf-8"?>
      <NetworkConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <EnableIPv6>true</EnableIPv6>
        <EnableIPv4>true</EnableIPv4>
        <LocalNetworkSubnets />
        <LocalNetworkAddresses />
        <KnownProxies />
        <PublishedServerUrl>https://${var.domains[0]}</PublishedServerUrl>
        <AutoDiscovery>true</AutoDiscovery>
        <EnableHttps>false</EnableHttps>
        <CertificatePath />
        <CertificatePassword />
        <BaseUrl />
        <EnableUPnP>false</EnableUPnP>
        <RequireHttps>false</RequireHttps>
        <InternalHttpPort>8096</InternalHttpPort>
        <InternalHttpsPort>8920</InternalHttpsPort>
        <PublicHttpPort>8096</PublicHttpPort>
        <PublicHttpsPort>8920</PublicHttpsPort>
        <EnableRemoteAccess>true</EnableRemoteAccess>
        <IgnoreVirtualInterfaces>true</IgnoreVirtualInterfaces>
        <VirtualInterfaceNames>
          <string>veth</string>
        </VirtualInterfaceNames>
        <EnablePublishedServerUriByRequest>false</EnablePublishedServerUriByRequest>
        <PublishedServerUriBySubnet />
        <RemoteIPFilter />
        <IsRemoteIPFilterBlacklist>false</IsRemoteIPFilterBlacklist>
      </NetworkConfiguration>
    XML
    
    "SSO-Auth.xml" = <<-XML
      <?xml version="1.0" encoding="utf-8"?>
      <PluginConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <SamlConfigs />
        <DefaultProvider>${var.oidc_client.provider_name}</DefaultProvider>
        <OidConfigs>
          <item>
            <key>
              <string>${var.oidc_client.provider_name}</string>
            </key>
            <value>
              <PluginConfiguration>
                <OidEndpoint>https://${var.oidc_client.provider_endpoint}</OidEndpoint>
                <OidClientId>${var.oidc_client.id}</OidClientId>
                <OidSecret>${var.oidc_client.secret}</OidSecret>
                <Enabled>true</Enabled>
                <EnableAuthorization>true</EnableAuthorization>
                <EnableAllFolders>true</EnableAllFolders>
                <EnabledFolders />
                <AdminRoles>
                  %{for role in var.oidc_client.admin_roles}<string>${role}</string>
                  %{endfor}
                </AdminRoles>
                <Roles>
                  %{for role in var.oidc_client.user_roles}<string>${role}</string>
                  %{endfor}
                </Roles>
                <EnableFolderRoles>false</EnableFolderRoles>
                <EnableLiveTvRoles>false</EnableLiveTvRoles>
                <EnableLiveTv>true</EnableLiveTv>
                <EnableLiveTvManagement>true</EnableLiveTvManagement>
                <LiveTvRoles />
                <LiveTvManagementRoles />
                <FolderRoleMappings />
                <OidScopes>
                  <string>groups</string>
                </OidScopes>
                <RoleClaim>groups</RoleClaim>
                <NewPath>false</NewPath>
                <CanonicalLinks />
                <DisableHttps>false</DisableHttps>
                <DoNotValidateEndpoints>false</DoNotValidateEndpoints>
                <DoNotValidateIssuerName>false</DoNotValidateIssuerName>
                <SchemeOverride>https</SchemeOverride>
              </PluginConfiguration>
            </value>
          </item>
        </OidConfigs>
      </PluginConfiguration>
    XML
    
    "branding.xml" = <<-XML
      <?xml version="1.0" encoding="utf-8"?>
      <BrandingOptions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <LoginDisclaimer></LoginDisclaimer>
        <CustomCss></CustomCss>
        <SplashscreenEnabled>false</SplashscreenEnabled>
      </BrandingOptions>
    XML
    
    "livetv.xml" = <<-XML
      <?xml version="1.0" encoding="utf-8"?>
      <LiveTvOptions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <GuideDays>7</GuideDays>
        <RecordingPath>/config/recordings</RecordingPath>
        <MovieRecordingPath>/config/recordings/movies</MovieRecordingPath>
        <SeriesRecordingPath>/config/recordings/series</SeriesRecordingPath>
        <EnableRecordingSubfolders>true</EnableRecordingSubfolders>
        <TunerHosts>
          %{if var.live_tv.m3u_url != null}
          <TunerHostInfo>
            <Id>m3u-tuner</Id>
            <Url>${var.live_tv.m3u_url}</Url>
            <Type>m3u</Type>
            <DeviceId>m3u-tuner</DeviceId>
            <FriendlyName>M3U Tuner</FriendlyName>
            <UserAgent>${coalesce(var.live_tv.user_agent, "Jellyfin")}</UserAgent>
            <ImportFavoritesOnly>false</ImportFavoritesOnly>
            <AllowHWTranscoding>true</AllowHWTranscoding>
            <EnableStreamLooping>false</EnableStreamLooping>
            <Source>Other</Source>
          </TunerHostInfo>
          %{endif}
        </TunerHosts>
        <ListingProviders>
          %{if var.live_tv.epg_url != null}
          <ListingsProviderInfo>
            <Id>xmltv-guide</Id>
            <Type>xmltv</Type>
            <Username />
            <Password />
            <ListingsId />
            <ZipCode />
            <Country />
            <Path>${var.live_tv.epg_url}</Path>
            <EnabledTuners>
              <string>m3u-tuner</string>
            </EnabledTuners>
            <EnableAllTuners>true</EnableAllTuners>
            <NewsCategories />
            <SportsCategories />
            <KidsCategories />
            <MovieCategories />
          </ListingsProviderInfo>
          %{endif}
        </ListingProviders>
      </LiveTvOptions>
    XML
    
    "Jellyfin.Plugin.CustomJavascript.xml" = <<-XML
    <?xml version="1.0" encoding="utf-8"?>
    <PluginConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
      <CustomJavaScript>// Configuration - Update this URL to match your SSO endpoint
    const SSO_AUTH_URL = 'https://${var.domains[0]}/sso/OID/start/${var.oidc_client.provider_name}';

    // Self-executing function that waits for the document body to be available
    (function waitForBody() {
      // If document.body doesn't exist yet, retry in 100ms
      if (!document.body) {
        return setTimeout(waitForBody, 100);
      }

      /**
       * Determines if the current page is a login page by checking multiple indicators
       * @returns {boolean} True if this appears to be a login page
       */
      function isLoginPage() {
        const hash = location.hash.toLowerCase();
        const pathname = location.pathname.toLowerCase();
        
        // Check for URL patterns that typically indicate login pages
        const hasLoginUrl = (
          hash === '' ||
          hash === '#/' ||
          hash === '#/home' ||
          hash === '#/login' ||
          hash.startsWith('#/login') ||
          pathname.includes('/login')
        );

        // Check for DOM elements that indicate a login form is present
        const hasLoginElements = (
          document.querySelector('input[type="password"]') !== null ||
          document.querySelector('.loginPage') !== null ||
          document.querySelector('#txtUserName') !== null
        );

        return hasLoginUrl || hasLoginElements;
      }

      /**
       * Checks if the current page should be excluded from SSO button insertion
       * These are typically pages where users are already authenticated
       * @returns {boolean} True if this page should be excluded
       */
      function shouldExcludePage() {
        const hash = location.hash.toLowerCase();
        
        // List of page patterns where we don't want to show the SSO button
        const excludePatterns = [
          '#/dashboard',
          '#/home.html',
          '#/movies',
          '#/tv',
          '#/music',
          '#/livetv',
          '#/search',
          '#/settings',
          '#/wizardstart',
          '#/wizardfinish',
          '#/mypreferencesmenu',
          '#/userprofile'
        ];

        return excludePatterns.some(pattern =&gt; hash.startsWith(pattern));
      }

      /**
       * Initializes the OAuth device ID in localStorage if it doesn't exist
       * This is required for Jellyfin native apps to maintain device identification
       */
      function oAuthInitDeviceId() {
        // Only set device ID if it's not already set and we're in a native shell environment
        if (!localStorage.getItem('_deviceId2') &amp;&amp; window.NativeShell?.AppHost?.deviceId) {
          localStorage.setItem('_deviceId2', window.NativeShell.AppHost.deviceId());
        }
      }

      /**
       * Creates and inserts the SSO login button into the login page
       * Only runs if we're on a valid login page and the button doesn't already exist
       */
      function insertSSOButton() {
        // Safety check: ensure we're on the right page before proceeding
        if (!isLoginPage() || shouldExcludePage()) return;

        // Try to find a suitable container for the SSO button
        const loginContainer = document.querySelector('.readOnlyContent') ||
                              document.querySelector('form')?.parentNode ||
                              document.querySelector('.loginPage') ||
                              document.querySelector('#loginPage');

        // Exit if no container found or button already exists
        if (!loginContainer || document.querySelector('#custom-sso-button')) return;

        // Skip insertion for Jellyfin Media Player (JMP) as it may have different auth handling
        const isJMP = navigator.userAgent.includes("JellyfinMediaPlayer");
        if (isJMP) return;

        // Create the SSO button element
        const button = document.createElement('button');
        button.id = 'custom-sso-button';
        button.className = 'raised block emby-button button-submit';
        
        // Style the button to match Jellyfin's design while being visually distinct
        button.style = 'display: flex; align-items: center; justify-content: center; gap: 10px; padding: 12px 20px; font-size: 16px; background-color: #3949ab; color: white; margin-top: 16px;';
        
        // Add icon and text content
        button.innerHTML = '&lt;span class="material-icons"&gt;shield&lt;/span&gt;&lt;span&gt;Login with SSO&lt;/span&gt;';
        
        // Handle button click - prevent form submission and redirect to SSO
        button.onclick = function (e) {
          e.preventDefault();
          oAuthInitDeviceId(); // Ensure device ID is set before SSO redirect
          window.location.href = SSO_AUTH_URL;
        };

        // Add the button to the login container
        loginContainer.appendChild(button);
      }

      // Initial setup: Check if we should insert the SSO button when script first loads
      if (isLoginPage() &amp;&amp; !shouldExcludePage()) {
        // Delay insertion slightly to ensure all page elements are fully loaded
        setTimeout(insertSSOButton, 500);
      }

      // Set up a MutationObserver to watch for dynamic page changes
      // This handles cases where Jellyfin loads content dynamically via JavaScript
      const observer = new MutationObserver(() =&gt; {
        if (isLoginPage() &amp;&amp; !shouldExcludePage()) {
          // Check if login elements are ready and button hasn't been inserted yet
          const ready = document.querySelector('.readOnlyContent') ||
                       document.querySelector('form') ||
                       document.querySelector('.loginPage');
          
          if (ready &amp;&amp; !document.querySelector('#custom-sso-button')) {
            insertSSOButton();
          }
        }
      });

      // Start observing changes to the entire document body and its children
      observer.observe(document.body, { childList: true, subtree: true });

      // Listen for hash changes (when navigating between pages in Jellyfin's SPA)
      window.addEventListener('hashchange', () =&gt; {
        // Small delay to allow page transition to complete
        setTimeout(() =&gt; {
          if (isLoginPage() &amp;&amp; !shouldExcludePage()) {
            insertSSOButton();
          }
        }, 300);
      });
    })();</CustomJavaScript>
    </PluginConfiguration>
    XML
  }
}

resource "kubernetes_job" "create_admin_user" {
  count = var.admin_password != "" ? 1 : 0
  
  metadata {
    name      = "${var.name}-create-admin"
    namespace = var.namespace
  }
  
  spec {
    template {
      metadata {}
      spec {
        restart_policy = "OnFailure"
        
        container {
          name  = "create-admin"
          image = "alpine:latest"
          
          command = ["/bin/sh"]
          args = ["-c", <<-EOF
            apk add --no-cache curl jq
            
            # Wait for Jellyfin to be ready
            echo "Waiting for Jellyfin to start..."
            until curl -s http://${var.name}.${var.namespace}.svc.cluster.local:8096/health; do
              echo "Jellyfin not ready yet, waiting..."
              sleep 5
            done
            
            # Check if setup is needed
            STARTUP_RESULT=$(curl -s http://${var.name}.${var.namespace}.svc.cluster.local:8096/Startup/Complete)
            if echo "$STARTUP_RESULT" | grep -q "true"; then
              echo "Jellyfin already configured, skipping user creation"
              exit 0
            fi
            
            # Create the initial admin user
            echo "Creating admin user..."
            curl -X POST "http://${var.name}.${var.namespace}.svc.cluster.local:8096/Startup/User" \
              -H "Content-Type: application/json" \
              -d '{
                "Name": "${var.admin_username}",
                "Password": "${var.admin_password}"
              }'
            
            # Complete the startup wizard
            curl -X POST "http://${var.name}.${var.namespace}.svc.cluster.local:8096/Startup/Complete"
            
            echo "Admin user created successfully"
          EOF
          ]
        }
      }
    }
  }
  
  depends_on = [
    helm_release.this,
    kubernetes_manifest.helm_release
  ]
}

resource "helm_release" "this" {
  count = var.flux_managed ? 0 : 1
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  values = [yamlencode(local.values)]
}

resource "kubernetes_manifest" "helm_repo" {
  count = var.flux_managed ? 1 : 0
  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "HelmRepository"
    metadata = {
      name      = var.chart_name
      namespace = var.namespace
    }
    spec = {
      interval = "5m"
      url      = var.chart_url
    }
  }
}

resource "kubernetes_manifest" "helm_release" {
  count = var.flux_managed ? 1 : 0
  manifest = {
    apiVersion = "helm.toolkit.fluxcd.io/v2"
    kind       = "HelmRelease"
    metadata = {
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      interval = "1m"
      releaseName = var.name
      chart = {
        spec = {
          chart   = var.chart_name
          version = var.chart_version
          sourceRef = {
            kind     = "HelmRepository"
            name     = var.chart_name
            namespace = var.namespace
          }
        }
      }
      targetNamespace = var.namespace
      values = jsondecode(jsonencode(local.values))
    }
  }
}


# resource "kubernetes_persistent_volume_claim" "config" {
#   metadata {
#     name = "${var.name}-config"
#     namespace = var.namespace
#   }
#   spec {
#     access_modes = ["ReadWriteOnce"]
#     resources {
#       requests = {
#         storage = var.config_storage
#       }
#     }
#     storage_class_name = var.storage_class
#   }
# }

# resource "kubernetes_persistent_volume_claim" "media" {
#  metadata {
#    name = "${var.name}-media"
#    namespace = var.namespace
#  }
#  spec {
#    access_modes = ["ReadWriteOnce"]
#    resources {
#      requests = {
#        storage = var.data_storage
#      }
#    }
#    storage_class_name = var.storage_class
#  }
# }

# resource "kubernetes_config_map" "sso_config" {
#   metadata {
#     name      = "${var.name}-sso-config"
#     namespace = var.namespace
#   }
#   data = {
#     "SSO-Auth.xml" = <<-XML
#       <?xml version="1.0" encoding="utf-8"?>
#       <PluginConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
#         <OidConfig>
#           <OidEndpoint>${var.oidc_provider_url}</OidEndpoint>
#           <OidClientId>jellyfin</OidClientId>
#           <OidSecret>${var.oidc_client_secret}</OidSecret>
#           <EnableAuthorization>true</EnableAuthorization>
#           <EnableAllFolders>true</EnableAllFolders>
#           <EnabledFolders />
#           <AdminPolicy>jellyfin-admins</AdminPolicy>
#           <DisableHttps>false</DisableHttps>
#           <SchemeOverride>https</SchemeOverride>
#         </OidConfig>
#       </PluginConfiguration>
#     XML
#   }
# }


# resource "kubernetes_deployment" "this" {
#   metadata {
#     name = var.name
#     namespace = var.namespace
#     labels = {
#       app = var.name
#       version = var.tag
#     }
#   }
#   spec {
#     replicas = var.replicas
#     strategy {
#       type = "RollingUpdate"
#       rolling_update {
#         max_surge = "1"
#         max_unavailable = "1"
#       }
#     }
#     selector {
#       match_labels = {
#         app = var.name
#         version = var.tag
#       }
#     }
#     template {
#       metadata {
#         name = var.name
#         labels = {
#           app = var.name
#           version = var.tag
#         }
#       }
#       spec {
#         node_selector = var.node_selectors
#         init_container {
#           name = "plugin-installer"
#           image = "alpine:latest"
#           command = ["/bin/sh"]
#           args = [

#           ]
# #           args = ["-c", <<-EOF
# #             echo "Setting up SSO plugin repository..."
# #             apk add --no-cache curl jq
# #             mkdir -p /config/data/plugins
# #             chown -R 1044:65541 /config/data/plugins
            
# #             # Add plugin repository configuration
# #             mkdir -p /config/plugins/repositories
# #             cat > /config/plugins/repositories/sso-plugin.json <<'PLUGINJSON'
# # {
# #   "repositoryUrl": "https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json",
# #   "repositoryName": "SSO-Auth Plugin Repository"
# # }
# # PLUGINJSON
            
# #             echo "SSO plugin repository configured"
# #             echo "Plugin will be available in Jellyfin's plugin catalog after startup"
# #             chown -R 1044:65541 /config
# #           EOF
# #           ]
#           security_context {
#             run_as_user = 0
#           }
#           volume_mount {
#             mount_path = "/config"
#             name = "config"
#           }
#         }
#         container {
#           name = "jellyfin"
#           image = "${var.image}:${var.tag}"
#           security_context {
#             privileged = true
#           }
#           port {
#             container_port = 8096
#             name = "http-tcp"
#             protocol = "TCP"
#           }
#           port {
#             container_port = 8920
#             name = "https-tcp"
#             protocol = "TCP"
#           }
#           port {
#             container_port = 1900
#             name = "dlna-udp"
#             protocol = "UDP"
#           }
#           port {
#             container_port = 7359
#             name = "discovery-udp"
#             protocol = "UDP"
#           }
#           env {
#             name = "JELLYFIN_PublishedServerUrl"
#             value = "https://${var.domains[0]}"
#           }
#           env {
#             name = "PGID"
#             value = "65541"
#           }
#           env {
#             name = "PUID"
#             value = "1044"
#           }
#           env {
#             name = "TZ"
#             value = "Europe/Berlin"
#           }
#           volume_mount {
#             mount_path = "/config"
#             name = "config"
#           }
#           volume_mount {
#             mount_path = "/config/plugins/configurations/SSO-Auth.xml"
#             name = "sso-config"
#             sub_path = "SSO-Auth.xml"
#           }
#           # volume_mount {
#           #   mount_path = "/media"
#           #   name = "media"
#           # }
#           dynamic "volume_mount" {
#             for_each = toset(var.shared_pvcs)
#             content {
#               mount_path = "/${volume_mount.value.name}"
#               name       = volume_mount.value.name
#             }
#           }
#         }
#         volume {
#           name = "config"
#           persistent_volume_claim {
#             claim_name = "${var.name}-config"
#           }
#         }
#         volume {
#           name = "media"
#           persistent_volume_claim {
#             claim_name = "${var.name}-media"
#           }
#         }
#         volume {
#           name = "sso-config"
#           config_map {
#             name = kubernetes_config_map.sso_config.metadata[0].name
#           }
#         }
#         dynamic "volume" {
#           for_each = toset(var.shared_pvcs)
#           content {
#             name = volume.value.name
#             persistent_volume_claim {
#               claim_name = volume.value.name
#             }
#           }
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_service" "tcp" {
#   metadata {
#     name = "${var.name}-tcp"
#     namespace = var.namespace
#   }
#   spec {
#     selector = {
#       app = var.name
#       version = var.tag
#     }
#     port {
#       name = "http-tcp"
#       port = 8096
#       target_port = 8096
#       protocol = "TCP"
#     }
#     port {
#       name = "https-tcp"
#       port = 8920
#       target_port = 8920
#       protocol = "TCP"
#     }
#   }
# }

# resource "kubernetes_service" "udp" {
#   metadata {
#     name = "${var.name}-udp"
#     namespace = var.namespace
#   }
#   spec {
#     session_affinity = "ClientIP"
#     selector = {
#       app = var.name
#       version = var.tag
#     }
#     port {
#       name = "dlna-udp"
#       port = 1900
#       target_port = 1900
#       protocol = "UDP"
#     }
#     port {
#       name = "discovery-udp"
#       port = 7359
#       target_port = 7359
#       protocol = "UDP"
#     }
#   }
# }

# resource "kubernetes_ingress_v1" "this" {
#   metadata {
#     name = var.name
#     namespace = var.namespace
#     annotations = local.ingress_annotations
#   }
#   spec {
#     ingress_class_name = var.ingress_class
#     tls {
#       secret_name = "${var.name}-tls"
#       hosts = var.domains
#     }
#     dynamic "rule" {
#       for_each = toset(var.domains)
#       content {
#         host = rule.value
#         http {
#           path {
#             path = "/"
#             backend {
#               service {
#                 name = "${var.name}-tcp"
#                 port {
#                   number = 8096
#                 }
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }
