#include "pass_element.hpp"

std::vector<UP<IPassElement>> HSPassElement::draw(Render::CRenderContext& ctx) {
    return {};
}

bool HSPassElement::needsLiveBlur(Render::CRenderContext& ctx) {
    return false;
}

bool HSPassElement::needsPrecomputeBlur(Render::CRenderContext& ctx) {
    return true;
}

bool HSPassElement::disableSimplification(Render::CRenderContext& ctx) {
    return true;
}
