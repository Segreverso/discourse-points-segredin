import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";

const userFrameCache = new Map();
const userFlairCache = new Map();

function currentUser(api) {
  return api.getCurrentUser?.() || api.container?.lookup?.("service:current-user");
}

function formatFrameClass(frameValue) {
  if (!frameValue) {
    return "";
  }
  return `jn-avatar-frame-${frameValue.toLowerCase().trim().replace(/_/g, "-")}`;
}

function formatFlairClass(flairValue) {
  if (!flairValue) {
    return "";
  }
  return `jn-user-flair-${flairValue.toLowerCase().trim().replace(/_/g, "-")}`;
}

function getUsernameFromAvatar(img) {
  if (!img) {
    return null;
  }

  // 1. Check parent <a> data-user-card attribute (Post stream, User cards)
  const cardLink = img.closest("[data-user-card]");
  if (cardLink) {
    const val = cardLink.getAttribute("data-user-card");
    if (val) {
      return val.toLowerCase().trim();
    }
  }

  // 2. Check parent <a> href="/u/username"
  const uLink = img.closest("a[href*='/u/']");
  if (uLink) {
    const href = uLink.getAttribute("href") || "";
    const match = href.match(/\/u\/([^\/]+)/i);
    if (match && match[1]) {
      return decodeURIComponent(match[1]).toLowerCase().trim();
    }
  }

  // 3. Check img title or alt attributes
  const title = (img.getAttribute("title") || "").replace(/^@/, "").trim().toLowerCase();
  if (title && !title.includes(" ") && title.length < 40) {
    return title;
  }

  const alt = (img.getAttribute("alt") || "").replace(/^@/, "").trim().toLowerCase();
  if (alt && !alt.includes(" ") && alt.length < 40) {
    return alt;
  }

  // 4. Check src URL pattern like /user_avatar/domain/username/...
  const src = img.getAttribute("src") || "";
  const srcMatch =
    src.match(/\/user_avatar\/[^\/]+\/([^\/]+)\//i) ||
    src.match(/\/letter_avatar_proxy\/[^\/]+\/[^\/]+\/([^\/]+)\//i);
  if (srcMatch && srcMatch[1]) {
    return srcMatch[1].toLowerCase().trim();
  }

  return null;
}

function applyAvatarFramesToDom(api) {
  const curUser = currentUser(api);
  const curUsername = curUser?.username ? curUser.username.toLowerCase().trim() : null;

  document
    .querySelectorAll("img.avatar, .user-profile-avatar img, .user-card-avatar img")
    .forEach((img) => {
      const isCurrentUserImg =
        img.closest(".current-user") ||
        img.closest(".header-dropdown-toggle") ||
        img.closest("#current-user") ||
        (curUsername &&
          (img.closest(`[data-user-card='${curUsername}']`) ||
            getUsernameFromAvatar(img) === curUsername));

      let frameVal = null;

      if (isCurrentUserImg && curUsername && userFrameCache.has(curUsername)) {
        frameVal = userFrameCache.get(curUsername);
      } else {
        const targetUser = getUsernameFromAvatar(img);
        if (targetUser && userFrameCache.has(targetUser)) {
          frameVal = userFrameCache.get(targetUser);
        }
      }

      // Clean existing jn-avatar-frame classes before applying new one
      const classList = Array.from(img.classList);
      classList.forEach((cls) => {
        if (cls.startsWith("jn-avatar-frame-")) {
          img.classList.remove(cls);
        }
      });

      if (frameVal) {
        const frameClass = formatFrameClass(frameVal);
        img.classList.add("jn-avatar-frame-active", frameClass);
      } else {
        img.classList.remove("jn-avatar-frame-active");
      }
    });
}

function applyUserFlairsToDom(api) {
  const curUser = currentUser(api);
  const curUsername = curUser?.username ? curUser.username.toLowerCase().trim() : null;

  document
    .querySelectorAll(".names a[data-user-card], .names .username, a.mention, .user-card .username, .user-profile .username")
    .forEach((el) => {
      let username = el.getAttribute("data-user-card") || el.dataset?.userCard;

      if (!username) {
        const cardLink = el.closest("[data-user-card]");
        if (cardLink) {
          username = cardLink.getAttribute("data-user-card");
        }
      }

      if (!username && el.classList.contains("mention")) {
        username = el.textContent.replace(/^@/, "").trim();
      }

      if (!username && el.getAttribute("href")) {
        const match = (el.getAttribute("href") || "").match(/\/u\/([^\/]+)/i);
        if (match && match[1]) {
          username = decodeURIComponent(match[1]);
        }
      }

      if (!username) {
        return;
      }

      username = username.toLowerCase().trim();

      let flairVal = userFlairCache.get(username) || userFrameCache.get(username);
      if (curUsername && username === curUsername && !flairVal) {
        flairVal = userFlairCache.get(curUsername) || userFrameCache.get(curUsername);
      }

      const classList = Array.from(el.classList);
      classList.forEach((cls) => {
        if (cls.startsWith("jn-user-flair-")) {
          el.classList.remove(cls);
        }
      });

      if (flairVal) {
        const flairClass = formatFlairClass(flairVal);
        el.classList.add("jn-user-flair-active", flairClass);
      } else {
        el.classList.remove("jn-user-flair-active");
      }
    });
}

function applyCosmeticsToDom(api) {
  applyAvatarFramesToDom(api);
  applyUserFlairsToDom(api);
}

function applyThemeSkin(themeSkin) {
  const root = document.documentElement;
  root.dataset.jnThemeSkin = themeSkin || "";
  root.classList.toggle("jn-theme-skin-starrail-neon", themeSkin === "starrail_neon");
}

async function fetchPublicUserCosmetics(api) {
  try {
    const response = await fetch("/loja/cosmeticos", {
      headers: { Accept: "application/json" },
    });
    if (response.ok) {
      const payload = await response.json();
      if (payload?.frames) {
        Object.entries(payload.frames).forEach(([user, frame]) => {
          if (user && frame) {
            userFrameCache.set(user.toLowerCase().trim(), frame);
          }
        });
      }
      if (payload?.flairs) {
        Object.entries(payload.flairs).forEach(([user, flair]) => {
          if (user && flair) {
            userFlairCache.set(user.toLowerCase().trim(), flair);
          }
        });
      }
    }
  } catch (_e) {
    // Non-blocking catch
  }
  applyCosmeticsToDom(api);
}

async function refreshCurrentUserCosmetics(api) {
  const curUser = currentUser(api);
  const username = curUser?.username;
  if (!username) {
    fetchPublicUserCosmetics(api);
    return;
  }

  try {
    const response = await fetch("/loja/inventario", {
      credentials: "same-origin",
      headers: { Accept: "application/json" },
    });
    if (response.ok) {
      const payload = await response.json();
      const frame = payload?.inventory?.equipped?.avatar_frame?.value;
      const flair = payload?.inventory?.equipped?.svip_glow?.value || payload?.inventory?.equipped?.card_border?.value;
      const themeSkin = payload?.inventory?.equipped?.theme_skin?.value;

      if (frame) {
        userFrameCache.set(username.toLowerCase().trim(), frame);
      } else {
        userFrameCache.delete(username.toLowerCase().trim());
      }

      if (flair) {
        userFlairCache.set(username.toLowerCase().trim(), flair);
      } else {
        userFlairCache.delete(username.toLowerCase().trim());
      }
      applyThemeSkin(themeSkin);
    }
  } catch (_error) {
    // Non-blocking catch
  }

  fetchPublicUserCosmetics(api);
}

export default apiInitializer("1.8.0", (api) => {
  if (api.addTrackedPostProperties) {
    api.addTrackedPostProperties("user_jn_cosmetic_avatar_frame");
  } else if (api.includePostAttributes) {
    api.includePostAttributes("user_jn_cosmetic_avatar_frame");
  }



  refreshCurrentUserCosmetics(api);

  window.addEventListener("jn:cosmetics-updated", (event) => {
    const inventory = event?.detail?.inventory || {};
    const curUser = currentUser(api);
    const username = curUser?.username;
    const frame = inventory?.equipped?.avatar_frame?.value;
    const flair = inventory?.equipped?.svip_glow?.value || inventory?.equipped?.card_border?.value;
    if (username) {
      if (frame) {
        userFrameCache.set(username.toLowerCase().trim(), frame);
      } else {
        userFrameCache.delete(username.toLowerCase().trim());
      }
      if (flair) {
        userFlairCache.set(username.toLowerCase().trim(), flair);
      } else {
        userFlairCache.delete(username.toLowerCase().trim());
      }
    }
    fetchPublicUserCosmetics(api);
    applyThemeSkin(inventory?.equipped?.theme_skin?.value);
  });

  api.onPageChange(() => {
    window.setTimeout(() => fetchPublicUserCosmetics(api), 100);
    window.setTimeout(() => applyCosmeticsToDom(api), 400);
  });

  // Observe DOM mutations to catch lazily rendered avatars in infinite scroll stream
  let debounceTimer = null;
  const observer = new MutationObserver(() => {
    if (debounceTimer) {
      clearTimeout(debounceTimer);
    }
    debounceTimer = setTimeout(() => {
      applyCosmeticsToDom(api);
    }, 150);
  });

  observer.observe(document.body, { childList: true, subtree: true });
});
