#include <linux/input-event-codes.h>

#include <cmath>

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/workspace/HLWorkspace.hpp>
#include <hyprland/src/output/Monitor.hpp>
#include <hyprland/src/managers/input/InputManager.hpp>
#include <hyprland/src/render/Renderer.hpp>

#include "config.hpp"
#include "globals.hpp"
#include "manager.hpp"

#include <hyprland/src/layout/LayoutManager.hpp>
#include <hyprland/src/layout/supplementary/DragController.hpp>
#include <hyprland/src/managers/fullscreen/FullscreenController.hpp>
#include <hyprland/src/state/MonitorState.hpp>

namespace {

constexpr double CLICK_SLOP = 6.0; // logical px of travel still counted as a click

bool isModifier(uint32_t keycode) {
    switch (keycode) {
        case KEY_LEFTSHIFT:
        case KEY_RIGHTSHIFT:
        case KEY_LEFTCTRL:
        case KEY_RIGHTCTRL:
        case KEY_LEFTALT:
        case KEY_RIGHTALT:
        case KEY_LEFTMETA:
        case KEY_RIGHTMETA: return true;
        default: return false;
    }
}

} // namespace

bool HSManager::shiftHeld() const {
    return m_modsHeld.contains(KEY_LEFTSHIFT) || m_modsHeld.contains(KEY_RIGHTSHIFT);
}

bool HSManager::anyModHeld() const {
    return !m_modsHeld.empty();
}

void HSManager::updateHover() {
    const auto view = viewFromCursor();
    if (!view)
        return;

    // Only a real pointer event arms hover. Without this the ring stays parked on whatever the
    // cursor happened to be over, and every keyboard step slides a different window underneath
    // it -- which looks like the overview highlighting windows at random.
    if (!view->m_hoverArmed)
        return;

    const auto coords = g_pInputManager->getMouseCoordsInternal();
    const auto window = view->windowAt(coords);

    if (view->m_hovered.lock() == window)
        return;

    view->m_hovered = window;

    if (const auto monitor = view->monitor()) {
        g_pHyprRenderer->damageMonitor(monitor);
        monitor->scheduleFrame();
    }
}

bool HSManager::onMouseMove() {
    if (!anyActive())
        return false;

    const auto coords = g_pInputManager->getMouseCoordsInternal();
    const auto view = viewFromCursor();

    if (m_foreignPress) {
        if (view && view->m_active && !view->m_closing) {
            if (const auto card = view->cardAt(coords); card && card->id != view->m_selected)
                view->selectWorkspace(card->id);
        }
        return false;
    }

    // A drag keeps the window that was picked up, even after the pointer crosses onto the
    // other monitor.
    if (m_dragging && m_pressView && m_pressView->m_dragged) {
        auto damage = [](const PHSVIEW& v) {
            if (!v)
                return;
            if (const auto monitor = v->monitor()) {
                g_pHyprRenderer->damageMonitor(monitor);
                monitor->scheduleFrame();
            }
        };

        const auto cursorMon = State::monitorState()->query().vec(coords).run();
        const auto pressMon = m_pressView->monitor();
        const bool otherMonitor = cursorMon && pressMon && cursorMon->m_id != pressMon->m_id;
        const bool destOverview = view && view != m_pressView && view->m_active && !view->m_closing;

        // The other monitor is showing its desktop. Hyprland's own move-drag is what carries a
        // window across outputs; the overview ghost cannot, because that monitor is not rendering
        // the overview. Swallowing the motion (return true) also skips moveMouse, so the window
        // would freeze on the monitor it was picked up from.
        if (otherMonitor && !destOverview && !m_handedOff && !m_handoffFailed) {
            const auto dragged = m_pressView->m_dragged.lock();
            if (const auto fs = Fullscreen::controller().get(); fs && cursorMon && fs->hasFullscreen(cursorMon)) {
                m_destWasFullscreen = true;
                m_displacedFullscreen = fs->getFullscreenWindow(cursorMon);
            }
            m_handedOff = m_pressView->startDesktopDrag(dragged);
            if (!m_handedOff)
                m_handoffFailed = true;
            else if (const auto fs = Fullscreen::controller().get(); fs && m_destWasFullscreen) {
                // A covering fullscreen window hides whatever is dropped on this monitor.
                if (const auto cover = m_displacedFullscreen.lock(); cover && cover != dragged)
                    fs->setFullscreenMode(cover, Fullscreen::FSMODE_NONE, Fullscreen::FSMODE_NONE, true);
            }
        }

        const bool backOnOverview = view && view->m_active && !view->m_closing;
        if (m_handedOff && backOnOverview) {
            // The desktop drag floated the window and moved it. Ending that and putting the
            // window back keeps the overview box where the pickup left it.
            if (g_layoutManager) {
                if (const auto& drag = g_layoutManager->dragController(); drag && drag->mode() != MBIND_INVALID)
                    drag->dragEnd();
            }
            m_pressView->recallDraggedWindow();
            m_handedOff = false;
            if (m_destWasFullscreen) {
                if (const auto fs = Fullscreen::controller().get(); fs)
                    if (const auto cover = m_displacedFullscreen.lock(); cover)
                        fs->setFullscreenMode(cover, Fullscreen::FSMODE_FULLSCREEN, Fullscreen::FSMODE_FULLSCREEN, true);
                m_destWasFullscreen = false;
                m_displacedFullscreen.reset();
            }
        }

        damage(m_pressView);
        if (destOverview) {
            damage(view);
        } else if (cursorMon) {
            g_pHyprRenderer->damageMonitor(cursorMon);
            cursorMon->scheduleFrame();
        }

        if (m_handedOff)
            return false;

        return true;
    }

    if (!view || !view->m_active || view->m_closing)
        return false;

    if (m_panning) {
        const float z = std::max(view->frame().zoom, 0.01F);
        // Divide by the zoom so the tape tracks the cursor 1:1 on screen, like niri's
        // right-drag view-offset gesture.
        view->panBy(-(coords.x - m_panLastPos.x) / z);
        m_panLastPos = coords;
        return true;
    }

    // Holding the select button and moving far enough lifts the window out of its row.
    // Use the view the press started on, not whichever monitor the pointer has since entered.
    if (m_buttonDown && m_pressView && !m_pressView->m_dragged && coords.distance(m_pressPos) > CLICK_SLOP) {
        if (m_pressView->beginDrag(m_pressPos))
            m_dragging = true;
    }

    if (m_pressView && m_pressView->m_dragged) {
        if (const auto monitor = view->monitor()) {
            g_pHyprRenderer->damageMonitor(monitor);
            monitor->scheduleFrame();
        }
        return true;
    }

    view->m_hoverArmed = true;
    updateHover();

    // Swallow motion so clients never see pointer coordinates that belong to a scaled-down
    // copy of themselves. The cursor itself keeps moving; only surface focus is suppressed.
    return true;
}

bool HSManager::onMouseButton(const IPointer::SButtonEvent& event) {
    const auto view = viewFromCursor();
    const bool pressed = event.state == WL_POINTER_BUTTON_STATE_PRESSED;
    const auto coords = g_pInputManager->getMouseCoordsInternal();
    const bool overviewHere = view && view->m_active && !view->m_closing;

    if (!overviewHere) {
        if (!pressed && m_dragging && m_pressView) {
            m_dragging = false;
            m_buttonDown = false;
            const bool takeFullscreen = m_destWasFullscreen;
            m_handedOff = false;
            m_handoffFailed = false;
            m_destWasFullscreen = false;
            m_displacedFullscreen.reset();
            const auto window = m_pressView->m_dragged.lock();
            m_pressView->cancelDrag();
            if (const auto monitor = State::monitorState()->query().vec(coords).run()) {
                m_pressView->dropToMonitor(window, monitor);
                // dropToMonitor fullscreens only when the monitor is fullscreen at the moment of
                // the drop. The drag already stepped that window aside so the window being
                // carried was visible, so put the dropped window up in its place.
                if (takeFullscreen && window) {
                    if (const auto fs = Fullscreen::controller().get(); fs && !fs->isFullscreen(window))
                        fs->setFullscreenMode(window, Fullscreen::FSMODE_FULLSCREEN, Fullscreen::FSMODE_FULLSCREEN, true);
                }
            }
            m_pressView.reset();
            m_pressWindow.reset();
            return true;
        }
        m_foreignPress = pressed && anyActive();
        return false;
    }

    if (m_foreignPress) {
        if (!pressed) {
            if (g_layoutManager) {
                const auto& drag = g_layoutManager->dragController();
                if (drag && drag->mode() != MBIND_INVALID) {
                    PHLWINDOW window = nullptr;
                    if (const auto target = drag->target())
                        window = target->window();
                    drag->dragEnd();
                    if (window)
                        view->acceptWindow(window, coords);
                } else if (const auto card = view->cardAt(coords)) {
                    view->selectWorkspace(card->id);
                }
            } else if (const auto card = view->cardAt(coords)) {
                view->selectWorkspace(card->id);
            }
            m_foreignPress = false;
            return true;
        }
        return false;
    }

    const uint32_t selectButton = (uint32_t)HSConfig::value<Config::INTEGER>("select_button");
    const uint32_t panButton = (uint32_t)HSConfig::value<Config::INTEGER>("pan_button");

    if (event.button == panButton && panButton != 0) {
        m_panning = pressed;
        m_panLastPos = coords;
        return true;
    }

    if (event.button != selectButton)
        return true; // still swallowed: no click in the overview should reach a client

    if (pressed) {
        m_buttonDown = true;
        m_pressPos = coords;
        m_pressView = view;
        m_pressWindow = view->windowAt(coords);
        return true;
    }

    if (!m_buttonDown)
        return true;

    m_buttonDown = false;

    if (m_dragging) {
        m_dragging = false;
        // A desktop drag may still be live if the pointer came back onto an overview. Ending it
        // here re-tiles the window; the card drop below then moves it onto the workspace under
        // the cursor.
        if (m_handedOff && g_layoutManager) {
            if (const auto& drag = g_layoutManager->dragController(); drag && drag->mode() != MBIND_INVALID)
                drag->dragEnd();
        }
        m_handedOff = false;
        m_handoffFailed = false;
        if (m_destWasFullscreen) {
            if (const auto fs = Fullscreen::controller().get(); fs)
                if (const auto cover = m_displacedFullscreen.lock(); cover)
                    fs->setFullscreenMode(cover, Fullscreen::FSMODE_FULLSCREEN, Fullscreen::FSMODE_FULLSCREEN, true);
            m_destWasFullscreen = false;
            m_displacedFullscreen.reset();
        }
        PHSVIEW drop = view;
        if (!drop || !drop->m_active || drop->m_closing)
            drop = m_pressView;
        if (m_pressView && drop && drop != m_pressView) {
            const auto window = m_pressView->m_dragged.lock();
            m_pressView->cancelDrag();
            drop->acceptWindow(window, coords);
        } else if (m_pressView) {
            m_pressView->endDrag(coords);
        } else {
            view->endDrag(coords);
        }
        m_pressView.reset();
        m_pressWindow.reset();
        return true;
    }

    // A click, not a drag.
    if (coords.distance(m_pressPos) <= CLICK_SLOP) {
        const auto window = view->windowAt(coords);

        if (window && window == m_pressWindow.lock()) {
            if (const auto ws = window->m_workspace)
                view->selectWorkspace(hs_workspace_id(ws));
            if (HSConfig::value<Config::INTEGER>("exit_on_click"))
                view->hide(window);
            return true;
        }

        // Clicking the empty band of a card selects that workspace and leaves.
        if (const auto card = view->cardAt(coords)) {
            view->selectWorkspace(card->id);
            if (HSConfig::value<Config::INTEGER>("exit_on_click"))
                view->hide(nullptr);
        }
    }

    m_pressWindow.reset();
    return true;
}

bool HSManager::onMouseAxis(const IPointer::SAxisEvent& event) {
    const auto view = viewFromCursor();
    if (!view || !view->m_active || view->m_closing)
        return false;

    const double speed = HSConfig::value<Config::FLOAT>("scroll_speed");
    if (event.delta == 0.0)
        return true;

    const int dir = event.delta > 0 ? 1 : -1;

    // Bare vertical wheel walks the workspace stack; shift (or a horizontal wheel) walks
    // columns along the tape. Same split as niri.
    if (event.axis == WL_POINTER_AXIS_HORIZONTAL_SCROLL || shiftHeld()) {
        view->selectColumn(dir);
        return true;
    }

    // Rate-limit so one flick of a free-spinning wheel does not fly past every workspace.
    const uint32_t cooldown = (uint32_t)std::max(1.0, 50.0 / std::max(speed, 0.1));
    if (event.timeMs != 0 && event.timeMs - m_lastRowScrollMs < cooldown)
        return true;
    m_lastRowScrollMs = event.timeMs;

    view->selectRow(dir);
    return true;
}

bool HSManager::onKey(const IKeyboard::SKeyEvent& event) {
    const bool pressed = event.state == WL_KEYBOARD_KEY_STATE_PRESSED;

    if (isModifier(event.keycode)) {
        if (pressed)
            m_modsHeld.insert(event.keycode);
        else
            m_modsHeld.erase(event.keycode);
        return false;
    }

    const auto view = viewFromCursor();
    if (!view || !view->m_active || view->m_closing)
        return false;

    if (!pressed)
        return false;

    // Anything with a modifier belongs to the user's own binds -- SUPER+SHIFT+L to swap columns,
    // ALT+2 to throw a window at workspace 2, and so on. Only bare keys are ours.
    if (anyModHeld())
        return false;

    // niri's hardcoded overview keys. Everything else falls through so the user's own binds
    // (including whatever toggles the overview) keep working.
    switch (event.keycode) {
        case KEY_ESC: view->hide(nullptr); return true;
        case KEY_ENTER: {
            const auto hovered = view->m_hovered.lock();
            view->hide(hovered ? hovered : view->selectedAnchor());
            return true;
        }
        case KEY_UP:
        case KEY_K: view->selectRow(-1); return true;
        case KEY_DOWN:
        case KEY_J: view->selectRow(1); return true;
        case KEY_LEFT:
        case KEY_H: view->selectColumn(-1); return true;
        case KEY_RIGHT:
        case KEY_L: view->selectColumn(1); return true;
        default: return false;
    }
}

void HSManager::swipeBegin(const IPointer::SSwipeBeginEvent& event) {
    m_swipeState = SWIPE_NONE;
    m_swipeAmount = 0.F;
}

bool HSManager::swipeUpdate(const IPointer::SSwipeUpdateEvent& event) {
    if (!HSConfig::value<Config::INTEGER>("gestures:enabled"))
        return false;

    const auto view = viewFromCursor();
    if (!view)
        return false;

    const uint32_t openFingers = (uint32_t)HSConfig::value<Config::INTEGER>("gestures:open_fingers");
    const float openDistance = std::max(HSConfig::value<Config::FLOAT>("gestures:open_distance"), 1.F);
    const bool openPositive = HSConfig::value<Config::INTEGER>("gestures:open_positive");

    if (event.fingers != openFingers)
        return view->m_active && !view->m_closing;

    const float dy = openPositive ? event.delta.y : -event.delta.y;

    if (m_swipeState != SWIPE_OPEN) {
        if (view->m_closing)
            return view->m_active;
        if (std::abs(event.delta.y) <= std::abs(event.delta.x))
            return view->m_active;

        if (!view->m_active && dy <= 0) {
            view->show();
            m_swipeState = SWIPE_OPEN;
            m_swipeAmount = openDistance;
        } else if (view->m_active && dy > 0) {
            m_swipeState = SWIPE_OPEN;
            m_swipeAmount = 0.F;
        }
    }

    if (m_swipeState == SWIPE_OPEN) {
        m_swipeAmount += dy;
        const float perc = 1.F - std::clamp(m_swipeAmount / openDistance, 0.01F, 1.F);
        view->m_progress->setValueAndWarp(perc);

        if (const auto monitor = view->monitor()) {
            g_pHyprRenderer->damageMonitor(monitor);
            monitor->scheduleFrame();
        }
        return true;
    }

    return view->m_active && !view->m_closing;
}

bool HSManager::swipeEnd() {
    const auto view = viewFromCursor();
    if (!view || m_swipeState == SWIPE_NONE)
        return false;

    const float perc = view->m_progress->value();
    if (perc >= 0.5F)
        view->show();
    else
        view->hide(nullptr);

    m_swipeState = SWIPE_NONE;
    m_swipeAmount = 0.F;
    return true;
}
