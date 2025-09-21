import ballerina/http;
import ballerina/io;
import ballerina/time;

type Assets record {|
    string AssetTag;
    string name;
    string faculty;
    string department;
    string status;
    time:Date acquiredDate;
    map<component> components;
    map<maintainance_schedule> maintainanceSchedules;
    map<workorder> workOrders;
|};

type component record {|
    string id?;
    string Name;
    string description;
    string serialNumber;
|};

type maintainance_schedule record {|
    string id?;
    string status;
    string scheduleType;
    time:Date nextDueDate;
    string description;
|};

type workorder record {|
    string id?;
    string status;
    string description;
    string title;
    string workorderstatus;
    time:Utc openedDate?;
    time:Utc completedDate?;
    map<task> tasks;
|};

type task record {|
    string id?;
    string description;
    string status;
    time:Utc openedDate?;
    time:Utc completedDate?;
|};

// -------------------- CLIENT --------------------
final http:Client equipClient = check new ("http://localhost:8080/equipserve");

// Example: Get all assets
function getAssets() returns error? {
    json response = check equipClient->get("/assets");
    io:println("All Assets: ", response.toJsonString());
}

// Example: Get asset by tag
function getAssetByTag(string tag) returns error? {
    Assets response = check equipClient->get("/assets/" + tag);
    io:println("Asset: ", response);
}

// Example: Add new asset
function addAsset() returns error? {
    Assets newAsset = {
        AssetTag: "", // Leave empty, server assigns UUID
        name: "Printer X100",
        faculty: "Engineering",
        department: "IT",
        status: "ACTIVE",
        acquiredDate: { year: 2024, month: 6, day: 12 },
        components: {},
        maintainanceSchedules: {},
        workOrders: {}
    };

    string resp = check equipClient->post("/assets", newAsset);
    io:println("Add Asset Response: ", resp);
}

// Example: Update asset
function updateAsset(string tag) returns error? {
    Assets updatedAsset = {
        AssetTag: tag,
        name: "Updated Printer",
        faculty: "Engineering",
        department: "IT",
        status: "ACTIVE",
        acquiredDate: { year: 2024, month: 6, day: 12 },
        components: {},
        maintainanceSchedules: {},
        workOrders: {}
    };

    string resp = check equipClient->put("/assets/" + tag, updatedAsset);
    io:println("Update Response: ", resp);
}

// Example: Delete asset
function deleteAsset(string tag) returns error? {
    string resp = check equipClient->delete("/assets/" + tag);
    io:println("Delete Response: ", resp);
}

// -------------------- MAIN --------------------
public function main() returns error? {
    // Call different client functions here
    check addAsset();
    check getAssets();
    // check getAssetByTag("your-tag-here");
    // check updateAsset("your-tag-here");
    // check deleteAsset("your-tag-here");
}
