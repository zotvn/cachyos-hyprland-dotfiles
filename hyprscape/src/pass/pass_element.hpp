#pragma once

#include <hyprland/src/render/pass/PassElement.hpp>

// A no-op pass element whose only job is to answer `true` to disableSimplification(Render::CRenderContext& ctx). Without
// it the render pass may decide an opaque element fully covers the ones behind it and drop
// them -- which is wrong once every element is being moved by a renderModif.
class HSPassElement : public IPassElement {
  public:
    HSPassElement() = default;
    virtual ~HSPassElement() = default;

    virtual std::vector<UP<IPassElement>> draw(Render::CRenderContext& ctx) override;
    virtual bool needsLiveBlur(Render::CRenderContext& ctx) override;
    virtual bool needsPrecomputeBlur(Render::CRenderContext& ctx) override;
    virtual bool disableSimplification(Render::CRenderContext& ctx) override;

    virtual ePassElementType type() override {
        return EK_CUSTOM;
    }

    virtual const char* passName() override {
        return "HSDisableSimplification";
    }
};
