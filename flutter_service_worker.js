'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "c3b8319b7414c96edadacd2d32455b0a",
".git/config": "4ea3cba5f29cfbcef0366ae2bdc47637",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "f5f9a358149d226ea9411013fed46ee5",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "ea85f41c5e1c8e377497af2704eb346c",
".git/logs/refs/heads/main": "ea85f41c5e1c8e377497af2704eb346c",
".git/logs/refs/remotes/origin/main": "25b7eacef441172c7ac5841a45f101fc",
".git/objects/02/6ffb6ceb42988932f47a26e048746e603eea28": "5594208a76d33011f403083d7cf51029",
".git/objects/03/2fe904174b32b7135766696dd37e9a95c1b4fd": "80ba3eb567ab1b2327a13096a62dd17e",
".git/objects/11/b211a5816386dbf6fb0edc15b2da75d319deb1": "a0a153bf1a16eede9bdf23c917a43380",
".git/objects/13/4d4054d7e98eda8582be0aa8a0f11a277fa6a6": "51b2f20e24babd21f4a1134e7106e031",
".git/objects/13/bf4ccf1549c3daef688a87423aefaa111e1064": "93a5e3bfbb730d3b55f6a9f9a898bc5c",
".git/objects/1b/c219978c4a958459152550d3ea1ace5bc85774": "d5658600a8661ba52760e5fd65e4bf48",
".git/objects/1c/09c4196e7597dc1f0d88f1db5e49c3d4660da6": "b4ce4cfc1deec230a85a58ca9cbffbb4",
".git/objects/20/2d002842bcb70ed57da4e82df4f4e96ab7a249": "9e7c0bf9978c01b5c886364ae56d3d94",
".git/objects/24/fbc9060dfadc418e1b331345a1f0bab60a869a": "f2efa26f646b4189c81ae7deab500be0",
".git/objects/25/c0d066dabfe99e6957d0fda6d8c49a3e65b194": "191301e9c58e97ae5637662b96523116",
".git/objects/2e/1018f35ed90e67af6eede1c9e7f99df91289f8": "d14d5f74c3424a7a78f5e284704c55b7",
".git/objects/2e/5f5f9619d2d7db5622851313f4afbd55ef4696": "29faf7c5abee5e09f84b1545ef9aaa35",
".git/objects/33/31d9290f04df89cea3fb794306a371fcca1cd9": "e54527b2478950463abbc6b22442144e",
".git/objects/35/96d08a5b8c249a9ff1eb36682aee2a23e61bac": "e931dda039902c600d4ba7d954ff090f",
".git/objects/37/a2bdd70ef5b204c05083c81dda1e42a4d484f4": "ac3e707ddde2e707ff9ca41f85bc2b13",
".git/objects/3a/bf18c41c58c933308c244a875bf383856e103e": "30790d31a35e3622fd7b3849c9bf1894",
".git/objects/40/1184f2840fcfb39ffde5f2f82fe5957c37d6fa": "1ea653b99fd29cd15fcc068857a1dbb2",
".git/objects/43/7731838b20e05c9f6e98f3e2b3c2b3f22f442a": "8a2881a81ab06b5649ebf456fd7b07ca",
".git/objects/49/31182c28c02c2214c534c6f690f364304ea891": "2c2e008407d0d41c8702ba73aaf4c4c9",
".git/objects/4a/4de224e2180ee24fcc3dd2b54bedd1d17e0a4c": "bc17a0b0bacfd350c13581e824c60194",
".git/objects/4f/02e9875cb698379e68a23ba5d25625e0e2e4bc": "254bc336602c9480c293f5f1c64bb4c7",
".git/objects/52/0d630565e201792ca7a07769034d599b949c37": "2e9ee7edf05230387831b0b7f81975e9",
".git/objects/53/3421c33062f0488a74a8a45ed8a3314ca0be7b": "c302d2b188d348f1920adb6742751fbc",
".git/objects/53/f78eb84e9debee6738dea714223969bda43f68": "ae42826a27a91006aea6f8b87f17ff33",
".git/objects/57/7946daf6467a3f0a883583abfb8f1e57c86b54": "846aff8094feabe0db132052fd10f62a",
".git/objects/58/75478e5c3f6b8f94647d18a6d58b90660926a2": "7f3031ef785e80b1cc85c553c2a2e47e",
".git/objects/59/a5262b8c99de0ad7fcf588bdb13ebd3ee7d445": "4f7aa6ca029892462b09f9dd99655d29",
".git/objects/5a/54fe5fe452f5d16a325db2635cf5f8f5201135": "ef89dd1044a0e533513684528691a03c",
".git/objects/5f/bf1f5ee49ba64ffa8e24e19c0231e22add1631": "f19d414bb2afb15ab9eb762fd11311d6",
".git/objects/63/6662370852f85a08f867845d75b7a181879d39": "b6fdccb98b66cc39b73eaf538748ce4f",
".git/objects/64/5116c20530a7bd227658a3c51e004a3f0aefab": "f10b5403684ce7848d8165b3d1d5bbbe",
".git/objects/66/682fda1a820b2ec16e5700f86bc16b1a1ffa1b": "ccc5e81e593943d4a97d6b50b8835799",
".git/objects/68/c2d7a05ee2c6a4ffdcd762b29ddc15c9dcb892": "6c07d9e595a07647d6eb86d14b6be02f",
".git/objects/6e/02f6e0f2b89da5d0e201035b81d73b767f0daf": "8c74d5e0be69d3584658835e990db68d",
".git/objects/71/7d4a5c91ee50f7c75dc77c1e4fb1a767a66997": "0ae8977ec41e6c15c26995ecef31eaf3",
".git/objects/7b/5c44bb074552259d63f4d52735011b58f27f06": "e73af6f160277ff392622099f330d1df",
".git/objects/7e/b6dc8fcfc953606c95106d8758f31db3bde788": "b2b5fc3b91bb0e3d8d2d3c95ce03f349",
".git/objects/86/d111f09a93cccfa0011858c519a823e7dafef7": "9a15839a59b5f501fbf7b9824c4b6f84",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/51a9b155d31c44b148d7e287fc2872e0cafd42": "9f785032380d7569e69b3d17172f64e8",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8f/368292a70675725b4d450fb31a7af7e7a2465c": "f772b016eabfd2336c517d3cfb18602d",
".git/objects/90/aca37bec148f3962480792f4c2fccfd9cbd2eb": "20b146c53af512c67f3041118ba93188",
".git/objects/90/ca1f5cae2b8f7d6f28b2f2e6a5d610dd80cad3": "992390d4db440096bebf34e04f69b322",
".git/objects/90/ef6ddec0d6b730a4936abf2479692886d7e0b1": "b7e532526f83cf8f6a31f806d4b49373",
".git/objects/91/4a40ccb508c126fa995820d01ea15c69bb95f7": "8963a99a625c47f6cd41ba314ebd2488",
".git/objects/92/38a90283e2f38fbf482b30c3d1f171d9c087d4": "8b89924166c5818a2c517b57e6d646aa",
".git/objects/93/be7fd9b9dcdd8564dafd7040a0c8c8f68d4080": "b27ff257c793a735fc818ff37f392ff9",
".git/objects/97/fffd5dd80ae60921070107a3ad6d2770cbe3a7": "a2d58ade51e99c82a9c7a6c3efe931c5",
".git/objects/9c/4fdc778309a5c106ac6bd5378452ea6403e916": "cc40677437ac6955c8d00d7fb06c2dcf",
".git/objects/9d/903e910d8c96cbf54fa661fbc862504c55b954": "f5ba200f710c53ac08827f79a8716566",
".git/objects/9e/26dfeeb6e641a33dae4961196235bdb965b21b": "304148c109fef2979ed83fbc7cd0b006",
".git/objects/a4/5caa26e21f4f9838faa9a8d90958033ba84919": "e5161114d9a3793c2879702e7bb6e53b",
".git/objects/a5/de584f4d25ef8aace1c5a0c190c3b31639895b": "9fbbb0db1824af504c56e5d959e1cdff",
".git/objects/a8/8c9340e408fca6e68e2d6cd8363dccc2bd8642": "11e9d76ebfeb0c92c8dff256819c0796",
".git/objects/a9/b892c42ed7a81dd2cd1f3ecfd0a0e331cf1f2e": "3c772b5064e06cd5336305a49825b848",
".git/objects/ac/15cf42472af11831803b35c2cfca7eb4cb6397": "1e1b9bd98764a927581c0a44d79f6662",
".git/objects/ac/fde0c092223dd1591bd419d6ec50543814bae0": "89df89462bfbc58239a3600836f44853",
".git/objects/ad/5b728570d4e070e8d8f8030458a138ac1d734f": "90c2bc1b4d67efe9fb86f518a0c0ec56",
".git/objects/ae/606c467701fbc1626df3869c886ed62fcf09a0": "811f6e1f5d79cb018d228bac56683e20",
".git/objects/b6/e3f17f0d40eb187ef76c148635f77a96ca4385": "1db2e2695c1ecb939f19f3ebb8e749f2",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/ba/382aff20c7f0d73b619b90277e2fd2fa9a1aa9": "d054de82ba5ca1c15f957a7597be38f4",
".git/objects/ba/80000d09c563d9408a59aa0014e8bc887a0066": "724adce5f2b39435215cd0a39c753953",
".git/objects/c2/67b63b29f9373767af68804cc1f3238b6ed4c6": "50677cf9e49dc27f9ee58bf887b12449",
".git/objects/c8/516f33559d49b9faf0657f4eb8370bc851d454": "1a6871474a3da70d35f16a066bed9b76",
".git/objects/cd/85c5cead88464b7fc02d2f3266e675777a01a0": "d46202212e0c636e82bb717805e3ba62",
".git/objects/d0/a82a88c0153ec47af20581e8361f61eb811d77": "de5f810f410605dba06266089d2f4183",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d9/3952e90f26e65356f31c60fc394efb26313167": "1401847c6f090e48e83740a00be1c303",
".git/objects/db/b35cf830b1896d82daa6291636eddf9fa1687a": "2771a46bfb67fc600b112e46d5bd35cd",
".git/objects/e4/0e50788b9e8e65d5bc502eb3c4b5c5c1d872e2": "2d5561baeca5c46b094c57748fd768b2",
".git/objects/e4/4882b4d69bf6593da8c85bdfa14c5f431bacd5": "e35c4b99b282c83eb289119e478f46b2",
".git/objects/e5/a6ca39c450408a7caf12862acf246da2db8438": "61187fd856ceb7cb54d0b7e19b3508d0",
".git/objects/e8/0b255cb5bcffe17e3a25d1f2f48de705f2b61f": "335d6534e24c060b4fe61ebaeaa0fc49",
".git/objects/e8/6c770373b3556900b7188fbb25f467760e9a15": "e69c19b5b05df8db45ad5bed834585c3",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/eb/fbf395f2e147425cf0ca105bbd8d28a290f608": "7759c53c7898b9d972e206108f5a5436",
".git/objects/ef/78d77995c2eed2f44157b4f74b0ddb48e658a7": "80727b093a24496e86fa8862d50e9a07",
".git/objects/ef/b875788e4094f6091d9caa43e35c77640aaf21": "27e32738aea45acd66b98d36fc9fc9e0",
".git/objects/ef/ccb6347ef598eab123f0e96e91c6c712a35e32": "0de84314c05352993f60be68cf649187",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f2/6984e9567e382b9e4343931d0c4a40d27054cd": "5c25bec508d148c63db2c77b1d45e252",
".git/objects/f3/709a83aedf1f03d6e04459831b12355a9b9ef1": "538d2edfa707ca92ed0b867d6c3903d1",
".git/objects/fa/f1d4e6c6de0336c6d024d3888462372d471d2f": "24f8480c43e296cfa2bc36c51918ae3f",
".git/refs/heads/main": "9dc23b384219c5228a7718ee64303976",
".git/refs/remotes/origin/main": "9dc23b384219c5228a7718ee64303976",
"assets/AssetManifest.bin": "0b0a3415aad49b6e9bf965ff578614f9",
"assets/AssetManifest.bin.json": "a1fee2517bf598633e2f67fcf3e26c94",
"assets/AssetManifest.json": "99914b932bd37a50b983c5e7c90ae93b",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/fonts/MaterialIcons-Regular.otf": "8ecbaaa018659f467f7cebeb75609a8b",
"assets/NOTICES": "8cafe7b9ebd5afd71bb3a6448a9e2a71",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"flutter_bootstrap.js": "5093f1f9186418d96f7a57fce946455a",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "51354b15d1a99517da0d43067cf7c7e1",
"/": "51354b15d1a99517da0d43067cf7c7e1",
"main.dart.js": "fb8e86a0457fdbc57ff4301604808560",
"manifest.json": "d8c69728f0c6f1c0c386780649c2d400",
"version.json": "abee529f6b759c7d26464abb64f92f81"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
