# DuneShine Employee App - API Documentation

## Service Flow Overview

The employee app follows this service flow sequence:
1. **Job Details** → View assigned job details
2. **Navigate** → Start navigation to customer location
3. **Reached** → Arrive at location, receive start OTP
4. **Verify OTP** → Verify customer's start OTP
5. **Start Wash** → Begin wash with before photo
6. **Finish Wash** → Complete wash with after photo, receive end OTP
7. **Complete** → Verify end OTP, job completed

---

## Base URLs
- **Production**: `https://duneshine.ae`
- **Staging**: `https://duneshine.bztechhub.com`

---

## API Endpoints

### 1. Get Today's Jobs
**Endpoint**: `GET /api/employee/jobs/today`  
**Screen**: `employee_home_screen.dart`  
**Purpose**: Fetch all jobs assigned to the employee for the current day.

#### Sample Response
```json
{
    "jobs": [
        {
            "id": 171,
            "booking_id": 103,
            "scheduled_date": "2026-02-01T20:00:00.000000Z",
            "start_time": "08:30:00",
            "status": "completed",
            "booking": {
                "id": 103,
                "customer": {
                    "name": "Sagar Rai",
                    "id_proof_image": "profile_photos/ZdIKEtFtkzprVWQbefAuJw4YCvvLFAWtjcms5n3P.jpg",
                    "phone": "+971989323305"
                },
                "vehicle": {
                    "brand_name": "Toyota",
                    "model": "Nexon",
                    "color": "Black",
                    "number_plate": "MP 04 23 2323"
                },
                "property": {
                    "id": 15,
                    "name": "Door 121",
                    "hierarchy_path": "Green View Society → Block A → Floor 2 → Door 121",
                    "resolved_location": {
                        "latitude": "23.1996395",
                        "longitude": "77.2410799"
                    }
                }
            },
            "time_slot": {
                "start_time": "17:00",
                "end_time": "20:00"
            }
        }
    ],
    "session_status": 1
}
```

---

### 2. Get Job Details
**Endpoint**: `GET /api/employee/jobs/{job_id}`  
**Screen**: `job_details_screen.dart`  
**Purpose**: Fetch complete job details with customer, vehicle, and booking information

#### Sample Response
```json
{
    "job": {
        "id": 175,
        "booking_id": 107,
        "scheduled_date": "2026-02-01T20:00:00.000000Z",
        "start_time": "10:00:00",
        "service_duration": 0,
        "travel_duration": 30,
        "time_slot_id": 6,
        "employee_id": 24,
        "status": "assigned",
        "assigned_at": "2026-02-02T13:13:08.000000Z",
        "start_otp": null,
        "start_otp_verified_at": null,
        "end_otp": null,
        "end_otp_verified_at": null,
        "en_route_at": null,
        "photos_before": null,
        "photos_after": null,
        "deleted_at": null,
        "created_at": "2026-02-02T13:12:43.000000Z",
        "updated_at": "2026-02-02T13:13:08.000000Z",
        "arrived_at": null,
        "started_at": null,
        "washed_at": null,
        "completed_at": null,
        "photos_before_urls": [],
        "photos_after_urls": [],
        "estimated_duration": 30,
        "end_time": "10:30",
        "booking": {
            "id": 107,
            "user_id": 49,
            "property_id": 15,
            "vehicle_id": 29,
            "apartment_id": null,
            "vendor_id": 2,
            "type": "on_demand",
            "subscription_package_id": null,
            "total_price": "200.00",
            "payment_status": "paid",
            "status": "confirmed",
            "expires_at": null,
            "services_payload": [
                {
                    "id": 5,
                    "name": "Interior Cleaning",
                    "price": "200.00"
                }
            ],
            "notes": null,
            "deleted_at": null,
            "created_at": "2026-02-02T13:12:43.000000Z",
            "updated_at": "2026-02-02T13:12:46.000000Z",
            "customer": {
                "id": 49,
                "name": "Sagar Rai",
                "email": "customer_1769855919@duneshine.com",
                "phone": "+971989323305",
                "id_proof_image": "profile_photos/ZdIKEtFtkzprVWQbefAuJw4YCvvLFAWtjcms5n3P.jpg"
            },
            "apartment": null,
            "vehicle": {
                "id": 29,
                "user_id": 49,
                "brand_name": "Toyota",
                "model": "Nexon",
                "color": "Black",
                "number_plate": "MP 04 23 2323"
            },
            "property": {
                "id": 15,
                "name": "Door 121",
                "type": "door",
                "parent_id": 3,
                "door_number": "121",
                "hierarchy_path": "Green View Society → Block A → Floor 2 → Door 121",
                "resolved_location": {
                    "latitude": "23.1996395",
                    "longitude": "77.2410799"
                },
                "parent": {
                    "id": 3,
                    "name": "Floor 2",
                    "type": "floor",
                    "parent_id": 2,
                    "hierarchy_path": "Green View Society → Block A → Floor 2",
                    "resolved_location": {
                        "latitude": "23.1996395",
                        "longitude": "77.2410799"
                    },
                    "parent": {
                        "id": 2,
                        "name": "Block A",
                        "type": "building",
                        "parent_id": 1,
                        "hierarchy_path": "Green View Society → Block A",
                        "resolved_location": {
                            "latitude": "23.1996395",
                            "longitude": "77.2410799"
                        },
                        "parent": {
                            "id": 1,
                            "name": "Green View Society",
                            "type": "society",
                            "parent_id": null,
                            "emirate": "Dubai",
                            "area": "Jumeirah Village Circle",
                            "community": "JVC District 10",
                            "latitude": "23.1996395",
                            "longitude": "77.2410799",
                            "google_maps_url": "https://www.google.com/maps?q=23.1996395,77.2410799",
                            "hierarchy_path": "Green View Society",
                            "resolved_location": {
                                "latitude": "23.1996395",
                                "longitude": "77.2410799"
                            },
                            "parent": null
                        }
                    }
                }
            }
        },
        "time_slot": {
            "id": 6,
            "start_time": "23:00",
            "end_time": "23:59",
            "status": true
        }
    }
}
```

#### Field Data Status

| Field Path | Has Data | Sample Value | Notes |
|------------|----------|--------------|-------|
| `job.id` | ✅ | `175` | Always present |
| `job.booking_id` | ✅ | `107` | Always present |
| `job.scheduled_date` | ✅ | `"2026-02-01T20:00:00.000000Z"` | ISO 8601 format |
| `job.start_time` | ✅ | `"10:00:00"` | HH:MM:SS format |
| `job.service_duration` | ✅ | `0` | Minutes |
| `job.travel_duration` | ✅ | `30` | Minutes |
| `job.time_slot_id` | ✅ | `6` | Reference to time_slot |
| `job.employee_id` | ✅ | `24` | Always present |
| `job.status` | ✅ | `"assigned"` | Status changes through flow |
| `job.assigned_at` | ✅ | `"2026-02-02T13:13:08.000000Z"` | Timestamp |
| `job.start_otp` | ❌ | `null` | Generated on arrival |
| `job.start_otp_verified_at` | ❌ | `null` | Set after OTP verification |
| `job.end_otp` | ❌ | `null` | Generated after wash finish |
| `job.end_otp_verified_at` | ❌ | `null` | Set after job completion |
| `job.en_route_at` | ❌ | `null` | Set when navigating |
| `job.photos_before` | ❌ | `null` | Array after start-wash |
| `job.photos_after` | ❌ | `null` | Array after finish-wash |
| `job.arrived_at` | ❌ | `null` | Set on arrival |
| `job.started_at` | ❌ | `null` | Set on wash start |
| `job.washed_at` | ❌ | `null` | Set on wash finish |
| `job.completed_at` | ❌ | `null` | Set on completion |
| `job.photos_before_urls` | ✅ | `[]` | Empty until photo uploaded |
| `job.photos_after_urls` | ✅ | `[]` | Empty until photo uploaded |
| `job.estimated_duration` | ✅ | `30` | Minutes |
| `job.end_time` | ✅ | `"10:30"` | HH:MM format |
| `job.booking.id` | ✅ | `107` | Booking reference |
| `job.booking.user_id` | ✅ | `49` | Customer user ID |
| `job.booking.property_id` | ✅ | `15` | Property reference |
| `job.booking.vehicle_id` | ✅ | `29` | Vehicle reference |
| `job.booking.apartment_id` | ❌ | `null` | Optional |
| `job.booking.vendor_id` | ✅ | `2` | Vendor reference |
| `job.booking.type` | ✅ | `"on_demand"` | Booking type |
| `job.booking.subscription_package_id` | ❌ | `null` | For subscription bookings |
| `job.booking.total_price` | ✅ | `"200.00"` | String format |
| `job.booking.payment_status` | ✅ | `"paid"` | Payment status |
| `job.booking.status` | ✅ | `"confirmed"` | Booking status |
| `job.booking.expires_at` | ❌ | `null` | For subscriptions |
| `job.booking.services_payload` | ✅ | `[{...}]` | Array of services |
| `job.booking.services_payload[].id` | ✅ | `5` | Service ID |
| `job.booking.services_payload[].name` | ✅ | `"Interior Cleaning"` | Service name |
| `job.booking.services_payload[].price` | ✅ | `"200.00"` | Service price |
| `job.booking.notes` | ❌ | `null` | Optional customer notes |
| `job.booking.customer.id` | ✅ | `49` | Customer ID |
| `job.booking.customer.name` | ✅ | `"Sagar Rai"` | Customer name |
| `job.booking.customer.email` | ✅ | `"customer_...@duneshine.com"` | Email |
| `job.booking.customer.id_proof_image` | ✅ | `"profile_photos/..."` | Photo path (needs base URL) |
| `job.booking.customer.phone` | ✅ | `"+971989323305"` | Customer phone |
| `job.booking.customer.address` | ❌ | `null` | Customer address |
| `job.booking.customer.rate` | ❌ | `null` | Customer rating |
| `job.booking.apartment` | ❌ | `null` | Apartment object (for apt bookings) |
| `job.booking.property.id` | ✅ | `15` | Property ID |
| `job.booking.property.name` | ✅ | `"Door 121"` | Property Name |
| `job.booking.property.hierarchy_path` | ✅ | `"Green View Society → ..."` | Full property path |
| `job.booking.property.resolved_location.latitude` | ✅ | `"23.1996395"` | **NEW**: Coordinate |
| `job.booking.property.resolved_location.longitude` | ✅ | `"77.2410799"` | **NEW**: Coordinate |
| `job.booking.vehicle.id` | ✅ | `29` | Vehicle ID |
| `job.booking.vehicle.brand_name` | ✅ | `"Toyota"` | Vehicle brand |
| `job.booking.vehicle.model` | ✅ | `"Nexon"` | Vehicle model |
| `job.booking.vehicle.color` | ✅ | `"Black"` | Vehicle color |
| `job.booking.vehicle.vehicle_type` | ❌ | `null` | Optional |
| `job.booking.vehicle.number_plate` | ✅ | `"MP 04 23 2323"` | License plate |
| `job.booking.vehicle.parking_notes` | ❌ | `null` | Optional parking instructions |
| `job.booking.vehicle.image` | ❌ | `null` | Vehicle image path |
| `job.booking.vehicle.image_url` | ❌ | `null` | Vehicle image URL |
| `job.time_slot.id` | ✅ | `6` | Time slot ID |
| `job.time_slot.start_time` | ✅ | `"23:00"` | Slot start time |
| `job.time_slot.end_time` | ✅ | `"23:59"` | Slot end time |
| `job.time_slot.status` | ✅ | `true` | Active status |

---

### 3. Navigate to Job
**Endpoint**: `POST /api/employee/jobs/{job_id}/navigate`  
**Screen**: `job_details_screen.dart` → `navigate_to_job_screen.dart`  
**Purpose**: Start navigation, status changes to "en_route"

#### Sample Response
```json
{
    "message": "Status updated to En Route. Navigation started.",
    "job": {
        "id": 159,
        "booking_id": 91,
        "scheduled_date": "2026-01-31T20:00:00.000000Z",
        "start_time": "12:30:00",
        "service_duration": 0,
        "travel_duration": 30,
        "time_slot_id": 4,
        "employee_id": 24,
        "status": "en_route",
        "assigned_at": "2026-02-01T11:31:49.000000Z",
        "start_otp": null,
        "start_otp_verified_at": null,
        "end_otp": null,
        "end_otp_verified_at": null,
        "en_route_at": "2026-02-01T11:45:12.000000Z",
        "photos_before": null,
        "photos_after": null,
        "deleted_at": null,
        "created_at": "2026-02-01T11:31:31.000000Z",
        "updated_at": "2026-02-01T11:45:12.000000Z",
        "arrived_at": null,
        "started_at": null,
        "washed_at": null,
        "completed_at": null,
        "photos_before_urls": [],
        "photos_after_urls": [],
        "estimated_duration": 30,
        "end_time": "13:00"
    }
}
```

#### Key Changes
- `status`: `"en_route"`
- `en_route_at`: Timestamp set
- **Note**: `booking` object NOT included - app uses `mergeWith()` to preserve from previous call

---

### 4. Reached/Arrived at Job
**Endpoint**: `POST /api/employee/jobs/{job_id}/reached`  
**Screen**: `navigate_to_job_screen.dart` → `MPINfillinfScreen.dart`  
**Purpose**: Mark arrival, generate start OTP

#### Sample Response
```json
{
    "message": "Status updated to Arrived. OTP generated.",
    "job": {
        "id": 159,
        "booking_id": 91,
        "scheduled_date": "2026-01-31T20:00:00.000000Z",
        "start_time": "12:30:00",
        "service_duration": 0,
        "travel_duration": 30,
        "time_slot_id": 4,
        "employee_id": 24,
        "status": "arrived",
        "assigned_at": "2026-02-01T11:31:49.000000Z",
        "start_otp": 5077,
        "start_otp_verified_at": null,
        "end_otp": null,
        "end_otp_verified_at": null,
        "en_route_at": "2026-02-01T11:45:12.000000Z",
        "photos_before": null,
        "photos_after": null,
        "deleted_at": null,
        "created_at": "2026-02-01T11:31:31.000000Z",
        "updated_at": "2026-02-01T11:55:54.000000Z",
        "arrived_at": "2026-02-01T11:55:54.000000Z",
        "started_at": null,
        "washed_at": null,
        "completed_at": null,
        "photos_before_urls": [],
        "photos_after_urls": [],
        "estimated_duration": 30,
        "end_time": "13:00"
    }
}
```

#### Key Changes
- `status`: `"arrived"`
- `start_otp`: `5077` (4-digit OTP generated)
- `arrived_at`: Timestamp set
- **Note**: `booking` object NOT included

---

### 5. Verify Start OTP
**Endpoint**: `POST /api/employee/jobs/{job_id}/verify-start-otp`  
**Screen**: `MPINfillinfScreen.dart`  
**Purpose**: Verify customer's start OTP before beginning wash
**Request Body**: `{ "otp": "5077" }`

#### Sample Response
```json
{
    "status": true,
    "message": "OTP Verified (or Skipped). Please upload photo."
}
```

#### Notes
- No job object returned
- Simple success/failure response

---

### 6. Start Wash
**Endpoint**: `POST /api/employee/jobs/{job_id}/start-wash`  
**Screen**: `screenToFillUserPin.dart` (JobArrivalPhotoScreen) → `washProgressShowingScreen.dart`  
**Purpose**: Begin wash with before-photo upload
**Request**: Multipart form with `photo` field

#### Sample Response
```json
{
    "message": "Wash started.",
    "job": {
        "id": 159,
        "booking_id": 91,
        "scheduled_date": "2026-01-31T20:00:00.000000Z",
        "start_time": "12:30:00",
        "service_duration": 0,
        "travel_duration": 30,
        "time_slot_id": 4,
        "employee_id": 24,
        "status": "in_progress",
        "assigned_at": "2026-02-01T11:31:49.000000Z",
        "start_otp": "5077",
        "start_otp_verified_at": "2026-02-01T11:58:40.000000Z",
        "end_otp": null,
        "end_otp_verified_at": null,
        "en_route_at": "2026-02-01T11:45:12.000000Z",
        "photos_before": [
            "job_photos/pCiQ3EFucOsLVZQRKY2zI4byWGoJFuQoYJy2rpkx.png"
        ],
        "photos_after": null,
        "deleted_at": null,
        "created_at": "2026-02-01T11:31:31.000000Z",
        "updated_at": "2026-02-01T11:59:51.000000Z",
        "arrived_at": "2026-02-01T11:55:54.000000Z",
        "started_at": "2026-02-01T11:59:51.000000Z",
        "washed_at": null,
        "completed_at": null,
        "photos_before_urls": [
            "https://duneshine.bztechhub.com/storage/job_photos/pCiQ3EFucOsLVZQRKY2zI4byWGoJFuQoYJy2rpkx.png"
        ],
        "photos_after_urls": [],
        "estimated_duration": 30,
        "end_time": "13:00"
    },
    "photo_url": "https://duneshine.bztechhub.com/storage/job_photos/pCiQ3EFucOsLVZQRKY2zI4byWGoJFuQoYJy2rpkx.png"
}
```

#### Key Changes
- `status`: `"in_progress"`
- `start_otp_verified_at`: Timestamp set
- `started_at`: Timestamp set
- `photos_before`: Array with uploaded photo path
- `photos_before_urls`: Array with full URLs
- `photo_url`: Direct URL of uploaded photo

---

### 7. Finish Wash
**Endpoint**: `POST /api/employee/jobs/{job_id}/finish-wash`  
**Screen**: `jobCOmpletionProofPhto.dart` → `jobCOmpleteOTPScreen.dart`  
**Purpose**: Complete wash with after-photo, generate end OTP
**Request**: Multipart form with `photo` field

#### Sample Response
```json
{
    "message": "Wash finished. Ask customer for completion OTP.",
    "job": {
        "id": 159,
        "booking_id": 91,
        "scheduled_date": "2026-01-31T20:00:00.000000Z",
        "start_time": "12:30:00",
        "service_duration": 0,
        "travel_duration": 30,
        "time_slot_id": 4,
        "employee_id": 24,
        "status": "washed",
        "assigned_at": "2026-02-01T11:31:49.000000Z",
        "start_otp": "5077",
        "start_otp_verified_at": "2026-02-01T11:58:40.000000Z",
        "end_otp": 7865,
        "end_otp_verified_at": null,
        "en_route_at": "2026-02-01T11:45:12.000000Z",
        "photos_before": [
            "job_photos/pCiQ3EFucOsLVZQRKY2zI4byWGoJFuQoYJy2rpkx.png"
        ],
        "photos_after": [
            "job_photos/3pccJTxyujtCkq9BD0EA6uZbPRtT47gZ4AuQlVKx.png"
        ],
        "deleted_at": null,
        "created_at": "2026-02-01T11:31:31.000000Z",
        "updated_at": "2026-02-01T12:01:27.000000Z",
        "arrived_at": "2026-02-01T11:55:54.000000Z",
        "started_at": "2026-02-01T11:59:51.000000Z",
        "washed_at": "2026-02-01T12:01:27.000000Z",
        "completed_at": null,
        "photos_before_urls": [
            "https://duneshine.bztechhub.com/storage/job_photos/pCiQ3EFucOsLVZQRKY2zI4byWGoJFuQoYJy2rpkx.png"
        ],
        "photos_after_urls": [
            "https://duneshine.bztechhub.com/storage/job_photos/3pccJTxyujtCkq9BD0EA6uZbPRtT47gZ4AuQlVKx.png"
        ],
        "estimated_duration": 30,
        "end_time": "13:00"
    },
    "photo_url": "https://duneshine.bztechhub.com/storage/job_photos/3pccJTxyujtCkq9BD0EA6uZbPRtT47gZ4AuQlVKx.png"
}
```

#### Key Changes
- `status`: `"washed"`
- `end_otp`: `7865` (4-digit completion OTP generated)
- `washed_at`: Timestamp set
- `photos_after`: Array with uploaded photo path
- `photos_after_urls`: Array with full URLs

---

### 8. Complete Job
**Endpoint**: `POST /api/employee/jobs/{job_id}/complete`  
**Screen**: `jobCOmpleteOTPScreen.dart` → `jobCompletedScreen.dart`  
**Purpose**: Verify end OTP and complete job
**Request Body**: `{ "otp": "7865" }`

#### Sample Response
```json
{
    "status": true,
    "message": "Job completed successfully!",
    "job": {
        "id": 159,
        "booking_id": 91,
        "scheduled_date": "2026-01-31T20:00:00.000000Z",
        "start_time": "12:30:00",
        "service_duration": 0,
        "travel_duration": 30,
        "time_slot_id": 4,
        "employee_id": 24,
        "status": "completed",
        "assigned_at": "2026-02-01T11:31:49.000000Z",
        "start_otp": "5077",
        "start_otp_verified_at": "2026-02-01T11:58:40.000000Z",
        "end_otp": "7865",
        "end_otp_verified_at": "2026-02-01T12:02:44.000000Z",
        "en_route_at": "2026-02-01T11:45:12.000000Z",
        "photos_before": [
            "job_photos/pCiQ3EFucOsLVZQRKY2zI4byWGoJFuQoYJy2rpkx.png"
        ],
        "photos_after": [
            "job_photos/3pccJTxyujtCkq9BD0EA6uZbPRtT47gZ4AuQlVKx.png"
        ],
        "deleted_at": null,
        "created_at": "2026-02-01T11:31:31.000000Z",
        "updated_at": "2026-02-01T12:02:44.000000Z",
        "arrived_at": "2026-02-01T11:55:54.000000Z",
        "started_at": "2026-02-01T11:59:51.000000Z",
        "washed_at": "2026-02-01T12:01:27.000000Z",
        "completed_at": "2026-02-01T12:02:44.000000Z",
        "photos_before_urls": [
            "https://duneshine.bztechhub.com/storage/job_photos/pCiQ3EFucOsLVZQRKY2zI4byWGoJFuQoYJy2rpkx.png"
        ],
        "photos_after_urls": [
            "https://duneshine.bztechhub.com/storage/job_photos/3pccJTxyujtCkq9BD0EA6uZbPRtT47gZ4AuQlVKx.png"
        ],
        "estimated_duration": 30,
        "end_time": "13:00"
    }
}
```

#### Key Changes
- `status`: `"completed"`
- `end_otp_verified_at`: Timestamp set
- `completed_at`: Timestamp set

---

## Status Flow Summary

| Status | Set By API | Timestamps Set |
|--------|------------|----------------|
| `assigned` | Initial assignment | `assigned_at` |
| `en_route` | `/navigate` | `en_route_at` |
| `arrived` | `/reached` | `arrived_at`, `start_otp` generated |
| `in_progress` | `/start-wash` | `started_at`, `start_otp_verified_at` |
| `washed` | `/finish-wash` | `washed_at`, `end_otp` generated |
| `completed` | `/complete` | `completed_at`, `end_otp_verified_at` |

---

## App Model Mapping

### Job Model Fields
| API Field | Model Property | Dart Type |
|-----------|---------------|-----------|
| `id` | `Job.id` | `int` |
| `booking_id` | `Job.bookingId` | `int` |
| `scheduled_date` | `Job.scheduledDate` | `String` |
| `status` | `Job.status` | `String` |
| `start_otp` | `Job.startOtp` | `String?` |
| `end_otp` | `Job.endOtp` | `String?` |
| `photos_before_urls` | `Job.photosBeforeUrls` | `List<String>` |
| `photos_after_urls` | `Job.photosAfterUrls` | `List<String>` |
| `booking` | `Job.booking` | `Booking?` |
| `time_slot` | `Job.timeSlot` | `TimeSlot?` |

### Booking Model Fields
| API Field | Model Property | Dart Type |
|-----------|---------------|-----------|
| `id` | `Booking.id` | `int` |
| `total_price` | `Booking.totalPrice` | `String` |
| `type` | `Booking.type` | `String` |
| `services_payload` | `Booking.servicesPayload` | `List<ServicePayload>` |
| `customer` | `Booking.customer` | `Customer?` |
| `vehicle` | `Booking.vehicle` | `Vehicle?` |
| `property` | `Job.booking.property` | `Property?` |

### Customer Model Fields
| API Field | Model Property | Dart Type |
|-----------|---------------|-----------|
| `id` | `Customer.id` | `int` |
| `name` | `Customer.name` | `String` |
| `phone` | `Customer.phone` | `String` |
| `id_proof_image` | `Customer.idProofImage` | `String?` |

### Vehicle Model Fields
| API Field | Model Property | Dart Type |
|-----------|---------------|-----------|
| `id` | `Vehicle.id` | `int` |
| `brand_name` | `Vehicle.brandName` | `String` |
| `model` | `Vehicle.model` | `String` |
| `color` | `Vehicle.color` | `String` |
| `number_plate` | `Vehicle.numberPlate` | `String` |

### Property Model Fields
| API Field | Model Property | Dart Type |
|-----------|---------------|-----------|
| `id` | `Property.id` | `int` |
| `name` | `Property.name` | `String` |
| `hierarchy_path` | `Property.hierarchyPath` | `String` |
| `resolved_location` | `Property.resolvedLocation` | `Map<String, String>` |
| `resolved_location['latitude']` | `Property.latitude` | `String` |
| `resolved_location['longitude']` | `Property.longitude` | `String` |

---

## Storage URL Pattern
- **Base Storage URL**: `https://duneshine.bztechhub.com/storage/`
- **Photo URLs**: Already complete URLs in `photos_before_urls` and `photos_after_urls`
- **Profile Photos**: Need to prepend storage base URL to `id_proof_image` path

**Example:**
```dart
// API returns: "profile_photos/ZdIKEtFtkzprVWQbefAuJw4YCvvLFAWtjcms5n3P.jpg"
// Full URL: "https://duneshine.bztechhub.com/storage/profile_photos/ZdIKEtFtkzprVWQbefAuJw4YCvvLFAWtjcms5n3P.jpg"
```

---

*Last Updated: 2026-02-02*
