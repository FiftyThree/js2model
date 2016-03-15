#include <iostream>
#include <fstream>

#include "catch.hpp"

#include "Variant.h"

using namespace boost;
using namespace json11;
using namespace std;

using namespace ft::js2model::test;

static Json LoadTestData(const string &jsonFile) {
    ifstream data(jsonFile);
    stringstream buffer;
    buffer << data.rdbuf();
    string error;
    auto testData = Json::parse(buffer.str(), error);
    if (!error.empty()) {
        cerr << "Error loading input data: " << error << endl;
        exit(-1);
    }
    return testData;
}

namespace boost
{
std::ostream& operator << ( std::ostream& os, none_t const& value ) {
    os << "boost::none";
    return os;
}

template<typename T>
std::ostream& operator << ( std::ostream& os, optional<T> const& value ) {
    if (value.is_initialized())
        os << "initialized";
    else
        os << none;
    return os;
}
}

TEST_CASE( "Test" ) {
    auto testData = LoadTestData("jsonData/variant.data.json");

    SECTION( "Fill layer" ) {
        auto obj = Variant(testData[0]);
        REQUIRE(obj.requiredLayerType() == "fill");
        const auto &fillLayer = boost::get<FillLayer>(obj.requiredLayer);
        REQUIRE(fillLayer.type == FillLayer::Type::Fill);
        REQUIRE(FillLayer::type_to_string(fillLayer.type) == "fill");
        REQUIRE(fillLayer.color.r == 255);
        REQUIRE(fillLayer.color.g == 255);
        REQUIRE(fillLayer.color.b == 0);
        REQUIRE(obj.is_valid());
        REQUIRE(obj.to_json().dump() == testData[0].dump());
        REQUIRE(obj.optionalLayer == boost::none);
        REQUIRE(obj.optionalLayers == boost::none);
        REQUIRE(obj.optionalLayerType() == boost::none);
        REQUIRE(obj.optionalLayersType(0) == boost::none);
        REQUIRE(obj.nullablePrimitive == boost::none);
    }

    SECTION( "Photo layer" ) {
        auto obj = Variant(testData[1]);
        REQUIRE(obj.requiredLayerType() == "photo");
        const auto &photoLayer = boost::get<PhotoLayer>(obj.requiredLayer);
        REQUIRE(photoLayer.type == PhotoLayer::Type::Photo);
        REQUIRE(PhotoLayer::type_to_string(photoLayer.type) == "photo");
        REQUIRE(photoLayer.blobId == "xhuN8r50BDX09Kq-kOcf1cZvzd2GKoc4DiN5fiMARcPEDrO9");
        REQUIRE(obj.is_valid());
        REQUIRE(obj.to_json().dump() == testData[1].dump());
        REQUIRE(obj.optionalLayer == boost::none);
        REQUIRE(obj.optionalLayers == boost::none);
        REQUIRE(obj.optionalLayerType() == boost::none);
        REQUIRE(obj.optionalLayersType(0) == boost::none);
        REQUIRE(obj.nullablePrimitive.is_initialized());
        REQUIRE(boost::get<int>(obj.nullablePrimitive.get()) == 1);
    }

    SECTION( "All layer combinations" ) {
        auto fillLayerData = testData[0]["requiredLayer"];
        auto photoLayerData = testData[1]["requiredLayer"];
        auto obj = Variant(testData[2]);

        REQUIRE(obj.requiredLayerType() == "photo");
        REQUIRE(boost::get<PhotoLayer>(obj.requiredLayer).to_json().dump() == photoLayerData.dump());

        REQUIRE(obj.nullablePrimitive.is_initialized());
        REQUIRE(boost::get<string>(obj.nullablePrimitive.get()) == "abc");

        REQUIRE(obj.optionalLayerType().get() == "fill");
        REQUIRE(boost::get<FillLayer>(obj.optionalLayer.get()).to_json().dump() == fillLayerData.dump());

        REQUIRE(obj.requiredLayers.size() == 2);
        REQUIRE(obj.requiredLayersType(0) == "photo");
        REQUIRE(boost::get<PhotoLayer>(obj.requiredLayers[0]).to_json().dump() == photoLayerData.dump());
        REQUIRE(obj.requiredLayersType(1) == "fill");
        REQUIRE(boost::get<FillLayer>(obj.requiredLayers[1]).to_json().dump() == fillLayerData.dump());

        REQUIRE(obj.optionalLayers.get().size() == 2);
        REQUIRE(obj.optionalLayersType(0).get() == "fill");
        REQUIRE(boost::get<FillLayer>(obj.optionalLayers.get()[0]).to_json().dump() == fillLayerData.dump());
        REQUIRE(obj.optionalLayersType(1).get() == "photo");
        REQUIRE(boost::get<PhotoLayer>(obj.optionalLayers.get()[1]).to_json().dump() == photoLayerData.dump());
    }
}
