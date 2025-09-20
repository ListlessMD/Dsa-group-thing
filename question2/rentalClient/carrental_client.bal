import ballerina/io;

CarRentalClient ep = check new ("http://localhost:9090");

public function main() returns error? {
    AddCarRequest addCarRequest = {car: {plate: "ballerina", make: "ballerina", model: "ballerina", year: 1, daily_price: 1, mileage: 1, status: "AVAILABLE"}};
    AddCarResponse addCarResponse = check ep->AddCar(addCarRequest);
    io:println(addCarResponse);

    CreateUsersRequest createUsersRequest = {users: [{username: "ballerina", name: "ballerina", role: "CUSTOMER"}]};
    CreateUsersResponse createUsersResponse = check ep->CreateUsers(createUsersRequest);
    io:println(createUsersResponse);

    UpdateCarRequest updateCarRequest = {plate: "ballerina", updated_car: {plate: "ballerina", make: "ballerina", model: "ballerina", year: 1, daily_price: 1, mileage: 1, status: "AVAILABLE"}};
    UpdateCarResponse updateCarResponse = check ep->UpdateCar(updateCarRequest);
    io:println(updateCarResponse);

    RemoveCarRequest removeCarRequest = {plate: "ballerina"};
    RemoveCarResponse removeCarResponse = check ep->RemoveCar(removeCarRequest);
    io:println(removeCarResponse);

    SearchCarRequest searchCarRequest = {plate: "ballerina"};
    SearchCarResponse searchCarResponse = check ep->SearchCar(searchCarRequest);
    io:println(searchCarResponse);

    AddToCartRequest addToCartRequest = {username: "ballerina", plate: "ballerina", start_date: "ballerina", end_date: "ballerina"};
    AddToCartResponse addToCartResponse = check ep->AddToCart(addToCartRequest);
    io:println(addToCartResponse);

    PlaceReservationRequest placeReservationRequest = {username: "ballerina"};
    PlaceReservationResponse placeReservationResponse = check ep->PlaceReservation(placeReservationRequest);
    io:println(placeReservationResponse);

    ListAvailableCarsRequest listAvailableCarsRequest = {filter: "ballerina"};
    stream<Car, error?> listAvailableCarsResponse = check ep->ListAvailableCars(listAvailableCarsRequest);
    check listAvailableCarsResponse.forEach(function(Car value) {
        io:println(value);
    });
}
