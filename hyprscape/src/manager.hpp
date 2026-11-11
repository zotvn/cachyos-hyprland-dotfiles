#pragma once

#include <string>
#include <unordered_set>
#include <vector>

#include <hyprland/src/devices/IKeyboard.hpp>
#include <hyprland/src/devices/IPointer.hpp>

#include "view.hpp"

class HSManager {
  public:
    std::vector<PHSVIEW> m_views;

    void rebuildViews();
    void removeViewForMonitor(MONITORID monitorId);

    PHSVIEW viewForMonitor(PHLMONITOR monitor) const;
    PHSVIEW viewFromCursor() const;

    bool anyRendering() const;
    bool anyActive() const;

    // arg is "all" (every monitor) or "cursor" (only the one under the pointer).
    void toggle(const std::string& arg);
    void show(const std::string& arg);
    void hide();

    void onConfigReloaded();

    // Input. Each returns true when the event must not reach the rest of the compositor.
    bool onMouseMove();
    bool onMouseButton(const IPointer::SButtonEvent& event);
    bool onMouseAxis(const IPointer::SAxisEvent& event);
    bool onKey(const IKeyboard::SKeyEvent& event);

    void swipeBegin(const IPointer::SSwipeBeginEvent& event);
    bool swipeUpdate(const IPointer::SSwipeUpdateEvent& event);
    bool swipeEnd();

  private:
    void updateHover();

    // Held modifier keycodes. The overview only claims a key when nothing is held, so binds
    // like SUPER+SHIFT+L keep reaching the user's own config.
    std::unordered_set<uint32_t> m_modsHeld;
    bool shiftHeld() const;
    bool anyModHeld() const;

    bool m_buttonDown = false;
    bool m_dragging = false;
    Vector2D m_pressPos;
    PHSVIEW m_pressView;
    PHLWINDOWREF m_pressWindow;

    bool m_panning = false;
    Vector2D m_panLastPos;

    // Super+G is cursor-only: a press that started on a monitor without overview must keep
    // reaching the compositor so a window can be dragged into the open overview.
    bool m_foreignPress = false;

    // Once the pointer leaves the overview onto a monitor that is showing the real desktop,
    // the window is in Hyprland's move-drag. Swallowing motion after that freezes it.
    bool m_handedOff = false;
    bool m_handoffFailed = false;
    // The other monitor was fullscreen when the drag crossed onto it. Its window is
    // unfullscreened for the drag, and the dropped window takes the screen on release.
    bool m_destWasFullscreen = false;
    PHLWINDOWREF m_displacedFullscreen;

    uint32_t m_lastRowScrollMs = 0;

    enum eSwipeState : uint8_t {
        SWIPE_NONE = 0,
        SWIPE_OPEN,
    };

    eSwipeState m_swipeState = SWIPE_NONE;
    float m_swipeAmount = 0.F;
};
