import ballerina/grpc;


map<User> users = {};
map<Car> cars = {}; 
map<CartItem> carts = {};
map<Reservation> reservations = {};



listener grpc:Listener ep = new (9090);

@grpc:Descriptor {value: RENTAL_DESC}
service "CarRental" on ep {

    remote function AddCar(AddCarRequest value) returns AddCarResponse|error {
        string plate =value.car.plate;
        if cars.hasKey(plate) {
            return error("Car with plate " + plate + " already exists.");
        }
        cars[plate] = value.car;
        return {plate: plate, message: "car added successfully"}; 
    }

    remote function CreateUsers(CreateUsersRequest value) returns CreateUsersResponse|error {
        foreach var user in value.users {
            if users.hasKey(user.username) {
                return error("User with the username " + user.username + " already exists.");
            }
            users[user.username] = user;  // This line is missing
        }
        return {message: "Users was created successfully!"};
    }

    remote function UpdateCar(UpdateCarRequest value) returns UpdateCarResponse|error {
        string plate = value.plate;
        if cars.hasKey(plate) {
            cars[plate] = value.updated_car;
        return {message: "car has been updated successfully"};

        } else {
            return error("Car with the plate " + plate + " does not exist.");
        }
        
    }

remote function RemoveCar(RemoveCarRequest value) returns RemoveCarResponse|error {
    string plate = value.plate;

   
    if cars.hasKey(plate) {
        
        _ = cars.remove(plate);

       
        Car[] remainingCars = [];
        foreach string key in cars.keys() {
            Car? car = cars[key];       
            if car is Car {             
                remainingCars.push(car);
            }
        }

       
        return { cars: remainingCars, message: "The car has been removed successfully" };
    } else {
       
        Car[] currentCars = [];
        foreach string key in cars.keys() {
            Car? c = cars[key];
            if c is Car {
                currentCars.push(c);
            }
        }

        return { cars: currentCars, message: "Car with the plate " + plate + " does not exist." };
    }
}


remote function SearchCar(SearchCarRequest value) returns SearchCarResponse|error {
    string plate = value.plate;

    Car? car = cars[plate]; // could be nil
    if car is Car {
        // Check if the car is available
        boolean isAvailable = car.status == AVAILABLE;
        return {car: car, available: isAvailable};
    } else {
        return error("Car with the plate " + plate + " does not exist.");
    }
}


    remote function AddToCart(AddToCartRequest value) returns AddToCartResponse|error {
        string username = value.username;
        string plate = value.plate;
        // Check if user exists
        if !users.hasKey(username) {
            return error("User " + username + " does not exist");
        }
        // Check if car exists and is available
        Car? car = cars[plate];
        if car is () {
            return error("Car with plate " + plate + " does not exist");
        }
        if car.status != AVAILABLE {
            return error("Car is not available for rental");
        }

        // Create cart if it doesn't exist
        if !carts.hasKey(username) {
            carts[username] = {};
        }

        // Add item to cart
        CartItem newItem = {
            plate: plate,
            start_date: value.start_date,
            end_date: value.end_date
        };
        CartItem[] userCart = [];
        userCart.push(carts.get(username));
        userCart.push(newItem);
        carts[username] = userCart[0];

        return {message: "Item added to cart successfully"};
    }

    remote function PlaceReservation(PlaceReservationRequest value) returns PlaceReservationResponse|error {
        string username = value.username;
        
        // Check if user exists
        if !users.hasKey(username) {
            return error("User " + username + " does not exist");
        }
        
        // Check if user has items in cart
        if !carts.hasKey(username) {
            return error("No items in cart");
        }
        
        CartItem[] userCart = [];
        userCart.push(carts.get(username));
        if userCart.length() == 0 {
            return error("Cart is empty");
        }
        
        // Calculate total price
        float totalPrice = 0;
        foreach CartItem item in userCart {
            Car? car = cars[item.plate];
            if car is Car {
                // In a real application, you would calculate the number of days between start_date and end_date
                // For now, we'll just use the daily price
                totalPrice += car.daily_price;
                
                // Update car status
                car.status = RENTED;
                cars[item.plate] = car;
            }
        }
        
        // Create reservation
        Reservation newReservation = {
            username: username,
            items: userCart,
            total_price: totalPrice
        };
        
        // Add to reservations map
        string reservationId = username + "-" + reservations.length().toString();
        reservations[reservationId] = newReservation;
        
        // Clear user's cart
        carts[username] ={};
        
        return {
            reservation: newReservation,
            message: "Reservation placed successfully"
        };
    }

    remote function ListAvailableCars(ListAvailableCarsRequest value) returns stream<Car, error?>|error {
        Car[] availableCars = [];
        foreach var car in cars {
            if car.status == AVAILABLE {
                // If filter is provided, check if car matches filter
                if value.filter != "" {
                    // Simple filter implementation - checks if make or model contains filter string
                    if car.make.toLowerAscii().includes(value.filter.toLowerAscii()) ||
                       car.model.toLowerAscii().includes(value.filter.toLowerAscii()) {
                        availableCars.push(car);
                    }
                } else {
                    availableCars.push(car);
                }
            }
        }
        return availableCars.toStream();
    }
}
