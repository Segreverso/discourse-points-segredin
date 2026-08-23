import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";

function currentUser(api) {
  return api.getCurrentUser?.() || api.container?.lookup?.("service:current-user");
}

function usernameFromApi(api) {
  return currentUser(api)?.username;
}

function clearAvatarFrames() {
  document.querySelectorAll("img[class*='jn-avatar-frame-']").forEach((node) => {
    node.className = node.className.replace(/\bjn-avatar-frame-\S+/g, "").trim();
  });
}

function applyThemeSkin(themeSkin) {
  const root = document.documentElement;
  root.dataset.jnThemeSkin = themeSkin || "";
  root.classList.toggle("jn-theme-skin-starrail-neon", themeSkin === "starrail_neon");
}

function applyAvatarFrame(username, frame) {
  clearAvatarFrames();
  document.documentElement.dataset.jnAvatarFrame = frame || "";

  if (!frame) {
    return;
  }

  const frameClass = `jn-avatar-frame-${frame.toLowerCase().replace(/_/g, "-")}`;

  const selectors = [
    ".header-dropdown-toggle.current-user img.avatar",
    ".current-user img.avatar",
    ".user-profile-avatar img.avatar",
    ".user-card-avatar img.avatar",
    "img.avatar",
  ];

  document.querySelectorAll(selectors.join(",")).forEach((img) => {
    const src = (img.getAttribute("src") || "").toLowerCase();
    const alt = (img.getAttribute("alt") || "").toLowerCase();
    const userLower = username ? username.toLowerCase() : "";

    if (
      img.closest(".header-dropdown-toggle.current-user") ||
      img.closest(".current-user") ||
      (userLower && (src.includes(`/${encodeURIComponent(userLower)}/`) || src.includes(`/${userLower}/`) || alt === userLower))
    ) {
      img.classList.add("jn-avatar-frame-active", frameClass);
    }
  });
}

async function refreshCurrentUserCosmetics(api) {
  const username = usernameFromApi(api);
  if (!username) {
    return;
  }

  try {
    const response = await fetch("/loja/inventario", {
      credentials: "same-origin",
      headers: { Accept: "application/json" },
    });
    if (!response.ok) {
      return;
    }

    const payload = await response.json();
    const frame = payload?.inventory?.equipped?.avatar_frame?.value;
    const themeSkin = payload?.inventory?.equipped?.theme_skin?.value;
    applyAvatarFrame(username, frame);
    applyThemeSkin(themeSkin);
  } catch (_error) {
    // Cosmetic rendering should never block normal forum navigation.
  }
}

export default apiInitializer("1.8.0", (api) => {
  if (currentUser(api)) {
    api.addNavigationBarItem({
      name: "points-mall",
      displayName: i18n("points_mall.title"),
      href: "/loja",
      classNames: ["points-mall-nav"],
      customFilter: () => !!currentUser(api),
      forceAfter: true,
    });
  }

  refreshCurrentUserCosmetics(api);

  window.addEventListener("jn:cosmetics-updated", (event) => {
    const inventory = event?.detail?.inventory || {};
    applyAvatarFrame(usernameFromApi(api), inventory?.equipped?.avatar_frame?.value);
    applyThemeSkin(inventory?.equipped?.theme_skin?.value);
  });

  api.onPageChange(() => {
    window.setTimeout(() => refreshCurrentUserCosmetics(api), 150);
  });
});
