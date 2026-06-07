{{flutter_js}}
{{flutter_build_config}}
(function() { var config = { serviceWorkerSettings: { serviceWorkerVersion: {{flutter_service_worker_version}} } }; var isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream; if (isIOS || /^((?!chrome|android).)*safari/i.test(navigator.userAgent)) { config.renderer = 'html'; } _flutter.loader.load(config); })();