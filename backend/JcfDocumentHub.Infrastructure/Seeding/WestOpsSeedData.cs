using JcfDocumentHub.Domain.WestOps;

namespace JcfDocumentHub.Infrastructure.Seeding;

/// <summary>
///   Deterministic seed data ported from <c>~/projects/WestOPs/sql/westapp.sql</c>.
///   Identifiers are stable across environments so the dataset stays comparable.
/// </summary>
internal static class WestOpsSeedData
{
    public static IReadOnlyList<WantedPerson> WantedPersons() => new List<WantedPerson>
    {
        new()
        {
            Id = "wanted-001",
            FirstName = "John",
            LastName = "Doe",
            Alias = "Johnny",
            Gender = "Male",
            DateOfBirth = new DateTime(1985, 5, 15, 0, 0, 0, DateTimeKind.Utc),
            CrimeDescription = "Robbery",
            PhotoUrl = "http://example.com/johndoe.jpg",
            RewardAmount = 5000m,
            ContactPhoneNumber = "555-1234",
            Status = "Wanted",
            IsVerified = true,
            ReporterUserId = 1
        },
        new()
        {
            Id = "wanted-002",
            FirstName = "Jane",
            LastName = "Smith",
            Alias = "Janie",
            Gender = "Female",
            DateOfBirth = new DateTime(1992, 8, 25, 0, 0, 0, DateTimeKind.Utc),
            CrimeDescription = "Fraud",
            PhotoUrl = "http://example.com/janesmith.jpg",
            RewardAmount = 10000m,
            ContactPhoneNumber = "555-5678",
            Status = "Wanted",
            IsVerified = true,
            ReporterUserId = 2
        },
        new()
        {
            Id = "wanted-003",
            FirstName = "Jack",
            LastName = "Black",
            Alias = "Jackie",
            Gender = "Male",
            DateOfBirth = new DateTime(1980, 11, 22, 0, 0, 0, DateTimeKind.Utc),
            CrimeDescription = "Assault",
            PhotoUrl = "http://example.com/jackblack.jpg",
            RewardAmount = 7000m,
            ContactPhoneNumber = "555-9012",
            Status = "Wanted",
            IsVerified = true,
            ReporterUserId = 3
        }
    };

    public static IReadOnlyList<MissingPerson> MissingPersons() => new List<MissingPerson>
    {
        new()
        {
            Id = "missing-001",
            FirstName = "Jane",
            LastName = "Smith",
            Gender = "Female",
            DateOfBirth = new DateTime(1990, 8, 20, 0, 0, 0, DateTimeKind.Utc),
            ReportedDate = new DateTime(2024, 7, 2, 0, 0, 0, DateTimeKind.Utc),
            LastSeenLocation = "Montego Bay",
            Description = "Last seen at the market",
            PhotoUrl = "http://example.com/photo2.jpg",
            ContactPerson = "John Smith",
            ContactPhoneNumber = "987-654-3210",
            Status = "Missing",
            IsVerified = true,
            ReporterUserId = 102
        }
    };

    public static IReadOnlyList<StolenVehicle> StolenVehicles() => new List<StolenVehicle>
    {
        new()
        {
            Id = "stolen-001",
            Make = "Toyota",
            Model = "Corolla",
            Year = 2015,
            Color = "White",
            LicensePlate = "ABC1234",
            Description = "Small dent on the rear bumper",
            DateStolen = new DateTime(2024, 6, 15, 0, 0, 0, DateTimeKind.Utc),
            LastKnownLocation = "Kingston",
            OwnerName = "John Doe",
            OwnerContact = "123-456-7890",
            RewardAmount = 500m,
            Status = "Stolen",
            IsVerified = true,
            ReporterUserId = 101,
            PhotoUrl = string.Empty
        },
        new()
        {
            Id = "stolen-002",
            Make = "Honda",
            Model = "Civic",
            Year = 2018,
            Color = "Black",
            LicensePlate = "XYZ5678",
            Description = "Scratch on the left door",
            DateStolen = new DateTime(2024, 7, 1, 0, 0, 0, DateTimeKind.Utc),
            LastKnownLocation = "Montego Bay",
            OwnerName = "Jane Smith",
            OwnerContact = "987-654-3210",
            RewardAmount = 1000m,
            Status = "Stolen",
            IsVerified = true,
            ReporterUserId = 102,
            PhotoUrl = string.Empty
        },
        new()
        {
            Id = "stolen-003",
            Make = "Ford",
            Model = "Focus",
            Year = 2012,
            Color = "Blue",
            LicensePlate = "LMN2345",
            Description = "Broken taillight",
            DateStolen = new DateTime(2024, 6, 25, 0, 0, 0, DateTimeKind.Utc),
            LastKnownLocation = "Negril",
            OwnerName = "Michael Johnson",
            OwnerContact = "555-123-4567",
            RewardAmount = 750m,
            Status = "Stolen",
            IsVerified = true,
            ReporterUserId = 103,
            PhotoUrl = string.Empty
        }
    };

    public static IReadOnlyList<TrafficCode> TrafficCodes() => new List<TrafficCode>
    {
        new()
        {
            Id = "tc-001",
            Code = "RTA-S51",
            Section = "Section 51",
            Offence = "Driving without a valid licence",
            FineAmount = 10000m,
            DemeritPoints = 6,
            Statute = "Road Traffic Act 2018"
        },
        new()
        {
            Id = "tc-002",
            Code = "RTA-S65",
            Section = "Section 65",
            Offence = "Exceeding the speed limit by more than 30 km/h",
            FineAmount = 15000m,
            DemeritPoints = 8,
            Statute = "Road Traffic Act 2018"
        },
        new()
        {
            Id = "tc-003",
            Code = "RTA-S72",
            Section = "Section 72",
            Offence = "Failure to wear a seat belt",
            FineAmount = 5000m,
            DemeritPoints = 2,
            Statute = "Road Traffic Act 2018"
        },
        new()
        {
            Id = "tc-004",
            Code = "RTA-S80",
            Section = "Section 80",
            Offence = "Use of a mobile device while driving",
            FineAmount = 10000m,
            DemeritPoints = 4,
            Statute = "Road Traffic Act 2018"
        }
    };
}
