#pragma once

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/workspace/HLWorkspace.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>
#include <hyprland/src/desktop/DesktopTypes.hpp>
#include <hyprland/src/helpers/time/Time.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprutils/math/Box.hpp>

using namespace Render;

typedef void (*render_workspace_t)(void* thisptr, Render::CRenderContext& ctx, PHLMONITOR monitor, PHLWORKSPACE workspace, const Time::steady_tp& now, const CBox& geometry);

typedef void (*render_window_t)(void* thisptr, Render::CRenderContext& ctx, PHLWINDOW window, PHLMONITOR monitor, const Render::SWindowRenderPresentation& presentation, const Time::steady_tp& time, bool decorate, eRenderPassMode mode, bool ignorePosition,
                                bool standalone);

typedef void (*render_layer_t)(void* thisptr, Render::CRenderContext& ctx, PHLLS layer, PHLMONITOR monitor, const Time::steady_tp& time, bool popups, bool lockscreen, bool workspaceScene);

typedef long VIEWID;

using WORKSPACEID = int64_t;
inline constexpr WORKSPACEID WORKSPACE_INVALID = -1;

inline WORKSPACEID hs_workspace_id(PHLWORKSPACE ws) { return ws && ws->numberedID() ? static_cast<WORKSPACEID>(*ws->numberedID()) : WORKSPACE_INVALID; }
