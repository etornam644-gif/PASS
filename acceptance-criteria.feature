Feature: Appointment Booking
  As a patient or clinic staff member
  I want to book an appointment into an available slot
  So that care can be scheduled without conflicts

  Background:
    Given the clinic operates between "08:00" and "18:00" on weekdays

  Scenario: Patient books an available slot
    Given a provider has an open slot at "2026-10-20T09:00:00Z"
    When the patient books an appointment for "2026-10-20T09:00:00Z"
    Then the system should confirm the booking
    And emit an "AppointmentCreated" event to the Notification Service
    And mark the slot as unavailable to other patients

  Scenario: Patient attempts to book an already-taken slot
    Given a provider's slot at "2026-10-20T09:00:00Z" is already booked
    When another patient attempts to book "2026-10-20T09:00:00Z"
    Then the system should reject the booking
    And display an error message indicating the slot is unavailable

  Scenario: Patient attempts to book outside clinic hours
    When a patient attempts to book an appointment for "2026-10-20T20:00:00Z"
    Then the system should reject the booking
    And display a message indicating the requested time is outside clinic hours


Feature: Appointment Rescheduling
  As a patient
  I want to reschedule an existing appointment
  So that I can change my visit time without creating a duplicate booking

  Scenario: Patient reschedules more than 24 hours before the original time
    Given a patient has a scheduled appointment for "2026-10-15T10:00:00Z"
    When the patient requests a reschedule to "2026-10-18T14:00:00Z"
    Then the system should update the appointment to the new time
    And emit an "AppointmentRescheduled" event to the Notification Service
    And display a confirmation message with the updated details to the patient

  Scenario: Patient reschedules within 24 hours of the original time
    Given a patient has a scheduled appointment for "2026-10-15T10:00:00Z"
    When the patient requests a reschedule to "2026-10-16T14:00:00Z"
    And the request is made less than 24 hours before the original time
    Then the system should apply a late-change flag to the appointment
    And emit an "AppointmentRescheduled" event to the Notification Service
    And display a confirmation message with the updated details to the patient

  Scenario: Patient reschedules to a slot that is already booked
    Given a patient has a scheduled appointment for "2026-10-15T10:00:00Z"
    And another appointment already occupies "2026-10-19T11:00:00Z"
    When the patient requests a reschedule to "2026-10-19T11:00:00Z"
    Then the system should reject the reschedule request
    And retain the original appointment time
    And display an error message indicating the new slot is unavailable


Feature: Appointment Cancellation
  As a patient
  I want to cancel an appointment I no longer need
  So that the slot becomes available to other patients

  Scenario: Patient cancels more than 24 hours in advance
    Given a patient has a scheduled appointment for "2026-10-20T09:00:00Z"
    When the patient cancels the appointment more than 24 hours before the scheduled time
    Then the system should mark the appointment as "Cancelled"
    And free the slot for other patients
    And emit an "AppointmentCancelled" event to the Notification Service

  Scenario: Patient cancels within 24 hours of the appointment
    Given a patient has a scheduled appointment for "2026-10-20T09:00:00Z"
    When the patient cancels the appointment less than 24 hours before the scheduled time
    Then the system should mark the appointment as "Cancelled"
    And apply a late-cancellation flag
    And emit an "AppointmentCancelled" event to the Notification Service


Feature: Appointment Reminders
  As a patient
  I want to receive a reminder before my appointment
  So that I don't miss my scheduled visit

  Scenario: System sends a reminder 24 hours before the appointment
    Given a patient has a confirmed appointment for "2026-10-20T09:00:00Z"
    When the current time reaches "2026-10-19T09:00:00Z"
    Then the system should emit a "ReminderDue" event to the Notification Service
    And the patient should receive a reminder via their preferred channel
