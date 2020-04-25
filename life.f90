! TODO:
!
!   - use logic such that if a point and its neighbors do not
!     change, don't check it in next frame
!
!   - parallelism does not seem to help for small grids

module lifemod

use pnmio

implicit none

character, parameter :: tab = char(9)
character(len = *), parameter :: me = "life"

integer, parameter ::        &
     ERR_POSITIVE_BOX = 400, &
     ERR_BAD_SEED     = 401, &
     ERR_WRITEPNM     = 402, &
     ERR_TXT_CHARS    = 403, &
     ERR_404          = 404, &
     ERR_CELLS_CHARS  = 405, &
     ERR_CELLS_COLS   = 406, &
     ERR_RLE_READ1    = 407, &
     ERR_RLE_READ2    = 408, &
     IO_SUCCESS = 0

type life_settings

  character(len = :), allocatable :: fjson, fseed

  integer :: n, xmin, xmax, ymin, ymax, pscale

  logical :: wrt, trans, invert

end type life_settings

contains

!=======================================================================

subroutine writerle(filename, g)

character :: filename*(*)

integer :: ifile, il, iu, jl, ju, ni, nj, j0, i, j, i0, length
integer, parameter :: lenmax = 69

logical*1 :: g0
logical*1, allocatable :: g(:,:)

il = lbound(g, 1)
iu = ubound(g, 1)
jl = lbound(g, 2)
ju = ubound(g, 2)

ni = iu - il + 1
nj = ju - jl + 1

open(newunit = ifile, file = filename)

write(ifile, '(a)') '# file '//trim(filename)//' generated by ' &
     //'writerle'
write(ifile, '(a, i0, a, i0)') 'x = ', nj, ', y = ', ni

length = 0
i = il
do while (i <= iu)
  i0 = i
  do while (.not. any(g(i, :)))
    i = i + 1
    if (i == iu) exit
  end do

  if (i - i0 > 0) then
    length = length + ceiling(log10(dble(i - i0 + 1)))
    if (length + 1 > lenmax) then
length = ceiling(log10(dble(i - i0 + 1)))
    write(ifile, *)
    end if
    write(ifile, '(i0)', advance = 'no') i - i0 + 1

    length = length + 1
    if (length > lenmax) then
length = 1
write(ifile, *)
    end if
    write(ifile, '(a)', advance = 'no') '$'

  else if (i > il) then
    length = length + 1
    if (length > lenmax) then
length = 1
write(ifile, *)
    end if
    write(ifile, '(a)', advance = 'no') '$'
  end if

  j = jl
  do while (j < ju)
    g0 = g(i, j)
    j0 = j
    do while (g(i, j + 1) .eqv. g0)
j = j + 1
if (j == ju) exit
    end do
    j = j + 1
    if (j - j0 > 1) then
length = length + ceiling(log10(dble(j - j0)))
if (length + 1 > lenmax) then
  length = ceiling(log10(dble(j - j0)))
  write(ifile, *)
end if
write(ifile, '(i0)', advance = 'no') j - j0
    end if
    if (g0) then
length = length + 1
if (length > lenmax) then
  length = 1
  write(ifile, *)
end if
write(ifile, '(a)', advance = 'no') 'o'
    else
length = length + 1
if (length > lenmax) then
  length = 1
  write(ifile, *)
end if
write(ifile, '(a)', advance = 'no') 'b'
    end if
  end do

  i = i + 1
end do

length = length + 1
if (length > lenmax) then
  length = 1
  write(ifile, *)
end if
write(ifile, '(a)', advance = 'no') '!'

close(ifile)

end subroutine writerle

!=======================================================================

function readrle(filename)

! Read seed grid in a run-length encoded format

character :: c, filename*(*), line*256, numchars(10)

integer :: ifile, ni, nj, i, j, k, k0, k1, runcount

logical*1, allocatable :: readrle(:,:)

numchars = [ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' ]

open(newunit = ifile, file = filename)

read(ifile, *) c
do while (c == '#')
  read(ifile, *) c
end do
!print *, 'c = ', c

backspace(ifile)
do while (c /= '=')
  read(ifile, '(a)', advance = 'no') c
  !print *, 'c = ', c
end do

read(ifile, *) nj
!print *, 'nj = ', nj

backspace(ifile)
do i = 1, 2
  read(ifile, '(a)', advance = 'no') c
  do while (c /= '=')
    read(ifile, '(a)', advance = 'no') c
    !print *, 'c = ', c
  end do
end do

read(ifile, *) ni
!print *, 'ni = ', ni

allocate(readrle(ni, nj))
readrle(:,:) = .false.

i = 1
j = 1

do while (c /= '!')
  read(ifile, '(a)') line
  !do k = 1, len_trim(line)
  k = 0
  do while (k < len_trim(line))
    k = k + 1

    c = line(k: k)
    !print *, 'c = ', c

    if (any(numchars == c)) then
k0 = k
k = k + 1
c = line(k: k)
do while (any(numchars == c))
  k = k + 1
  c = line(k: k)
end do
k1 = k - 1
!print *, 'runcount = ', line(k0: k1)
read(line(k0: k1), *) runcount
!print *, 'runcount = ', runcount
!print *, 'i, j = ', i, j
!print *, 'c = ', c

if (c == 'b') then
  readrle(i, j: j + runcount - 1) = .false.
  j = j + runcount
else if (c == 'o') then
  readrle(i, j: j + runcount - 1) = .true.
  j = j + runcount
else if (c == '$') then
  i = i + runcount
  j = 1
else
  write(*,*)
  write(*,*) 'Error reading RLE file.'
  write(*,*) 'Bad character '//c//' after runcount ' &
      //line(k0: k1)
  write(*,*)
  call exit(ERR_RLE_READ1)
end if
    else if (c == 'b') then
readrle(i, j) = .false.
j = j + 1
    else if (c == 'o') then
readrle(i, j) = .true.
j = j + 1
    else if (c == '$') then
i = i + 1
j = 1
    else if (c == '!') then
! End of file.  Do nothing.
    else
write(*,*)
write(*,*) 'Error reading RLE file.'
write(*,*) 'Bad character '//c//'.'
write(*,*)
call exit(ERR_RLE_READ2)
    end if
  end do
end do

close(ifile)

end function readrle

!=======================================================================

function readcells(filename)

character :: filename*(*), c, line*8096

integer :: ifile, ni, nj, i, j, io

logical*1, allocatable :: readcells(:,:)

! Read seed grid in the format of a matrix of 0's and 1's.
open(newunit = ifile, file = filename)

read(ifile, *) c
do while (c == '!')
  read(ifile, *) c
end do
backspace(ifile)

! Find size
read(ifile, '(a)') line
nj = len_trim(line)

if (nj == 8096) then
  write(*,*)
  write(*,*) 'Error'
  write(*,*) 'Too many columns in '//trim(filename)
  write(*,*) 'Increase line length and re-compile.'
  write(*,*)
  call exit(ERR_CELLS_COLS)
end if

rewind(ifile)
read(ifile, *) c
do while (c == '!')
  read(ifile, *) c
end do
backspace(ifile)

io = 0
ni = 0
do while (io == 0)
  read(ifile, '(a)', iostat = io) c
  ni = ni + 1
end do
ni = ni - 1

rewind(ifile)
read(ifile, *) c
do while (c == '!')
  read(ifile, *) c
end do
backspace(ifile)

allocate(readcells(1: ni, 1: nj))
do i = 1, ni
  do j = 1, nj

    if (j < nj) then
read(ifile, '(a)', advance = 'no') c
    else
read(ifile, '(a)', advance = 'yes') c
    end if

    if (c == '.') then
readcells(i, j) = .false.
    else if (c == 'O') then
readcells(i, j) = .true.
    else
write(*,*)
write(*,*) 'Error reading input file '//trim(filename)
write(*,*) 'Input grid must consist of .''s and O''s'
write(*,*)
call exit(ERR_CELLS_CHARS)
    end if
  end do
end do
close(ifile)

end function readcells

!=======================================================================

function readtxt(filename)

! Read seed grid in the format of a matrix of 0's and 1's with the
! matrix size in the header.

character :: filename*(*)

integer :: ifile, ni, nj, i, j
integer, allocatable :: kalloc(:)

logical*1, allocatable :: readtxt(:,:)

open(newunit = ifile, file = filename)
read(ifile, *) ni
read(ifile, *) nj
allocate(readtxt (1: ni, 1: nj))
allocate(kalloc(nj))
do i = 1, ni
  read(ifile, *) kalloc(:)
  do j = 1, nj
    if (kalloc(j) == 0) then
readtxt(i, j) = .false.
    else if (kalloc(j) == 1) then
readtxt(i, j) = .true.
    else
write(*,*)
write(*,*) 'Error reading input file '//trim(filename)
write(*,*) 'Input grid must consist of 0''s and 1''s'
write(*,*)
call exit(ERR_TXT_CHARS)
    end if
  end do
end do
close(ifile)

end function readtxt

!=======================================================================


subroutine writelifepnm(filename, g, settings)

! filenamename of the file to be written to
!
! g logical grid of live/dead cells

! Could also add fliplr and flipud options.

character :: filename*(*), c1, c0
character, allocatable :: b(:,:)

integer :: i, j, il, iu, jl, ju, n1, n2, n3, n4, n13, n24, frm, &
    io, i0, i1, ii, jj, j8, ig, jg, ilo, ihi, jlo, jhi, s

logical, parameter :: ascii = .false.
logical :: tran
logical*1, allocatable :: g(:,:)

type(life_settings) :: settings

n1 = settings%xmin
n2 = settings%ymin
n3 = settings%xmax
n4 = settings%ymax
s = settings%pscale

tran = settings%trans

! FFMPEG requires dimensions in multiples of 2.
n13 = (n3 - n1)
n24 = (n4 - n2)
if (mod(n13, 2) == 0) n3 = n3 + 1
if (mod(n24, 2) == 0) n4 = n4 + 1

if (tran) then
  il = lbound(g, 2)
  iu = ubound(g, 2)
  jl = lbound(g, 1)
  ju = ubound(g, 1)
else
  il = lbound(g, 1)
  iu = ubound(g, 1)
  jl = lbound(g, 2)
  ju = ubound(g, 2)
end if

if (ascii) then

  frm = 1
  allocate(b(n4 - n2 + 1, n3 - n1 + 1))

else

  ! Binary:  pack 8 B&W pixel bits into a 1 byte character.
  ! Only the horizontal dimension is padded.
  frm = 4
  allocate(b(ceiling((n4 - n2 + 1) / 8.d0) * s, &
      (n3 - n1 + 1) * s))

end if

if (settings%invert) then
  i0 = 1
  i1 = 0
  if (.not. ascii) b = achar(0)! 00000000
else
  i0 = 0
  i1 = 1
  if (.not. ascii) b = achar(z'ff')  ! 11111111
end if
c0 = achar(i0)
c1 = achar(i1)

if (ascii) b = c1

! Array b is scaled by the pixel scaling factor settings%pscale,
! but array g is not.  Loop the b indices i and j faster than the
! g indices ig and jg.

ilo = max(n1, il)
ihi = min(n3, iu)
ig = ilo - 1
do i = ilo * s, ihi * s
  if (mod(i, s) == 0) ig = ig + 1
  ii = n3 * s - i + 1

  jlo = max(n2, jl)
  jhi = min(n4, ju)
  jg = jlo - 1
  do j = jlo * s, jhi * s
    if (mod(j, s) == 0) jg = jg + 1
    if (((.not. tran) .and. g(ig,jg)) &
         .or.  (tran  .and. g(jg,ig))) then
j8 = j - n2 * s + 1

if (ascii) then
  b(j8, ii) = c0
else

  ! j8 is the bitwise index and jj is the bytewise index.
  ! Use mod(j8,8) to get the endian-flipped index of the bit
  ! within the byte to be set or cleared.  ichar(.,1) casts
  ! a character to a 1-byte int, and achar casts the int
  ! back to a character.

  jj = j8 / 8

  if (settings%invert) then
    b(jj,ii) = achar(ibset(ichar(b(jj,ii), 1), 7 - mod(j8,8)))
  else
    b(jj,ii) = achar(ibclr(ichar(b(jj,ii), 1), 7 - mod(j8,8)))
  end if

end if
    end if
  end do
end do

io = writepnm(frm, b, filename, .false.)
if (io /= 0) call exit(ERR_WRITEPNM)

end subroutine writelifepnm

!=======================================================================

subroutine nextgen(filepre, settings, dead, g0, g, n, &
    niminmin, njminmin, nimaxmax, njmaxmax, frames)

character :: cn*256, filepre*256, fres*256, frames*256

integer :: i, j, n, nimin, njmin, nimax, njmax, nimin0, &
     nimax0, njmin0, njmax0, nbrs, niminmin, nimaxmax,  &
     njminmin, njmaxmax

logical, intent(inout) :: dead
logical*1, allocatable :: g(:,:), g0(:,:)

type(life_settings) :: settings

! Trim or extend the grid.
nimin0 = lbound(g0, 1)
njmin0 = lbound(g0, 2)
nimax0 = ubound(g0, 1)
njmax0 = ubound(g0, 2)

nimin = nimin0
njmin = njmin0
nimax = nimax0
njmax = njmax0

if (count(g0(:,:)) == 0) then
  write(*,*)
  write(*,*) 'The pattern has disappeared.'
  write(*,*)
  dead = .true.
end if

do while (all(.not. g0(nimin, :)))
  nimin = nimin + 1
end do
do while (all(.not. g0(:, njmin)))
  njmin = njmin + 1
end do
do while (all(.not. g0(nimax, :)))
  nimax = nimax - 1
end do
do while (all(.not. g0(:, njmax)))
  njmax = njmax - 1
end do
nimin = nimin - 1
njmin = njmin - 1
nimax = nimax + 1
njmax = njmax + 1

deallocate(g)
allocate(g(nimin: nimax, njmin: njmax))

niminmin = min(niminmin, nimin)
njminmin = min(njminmin, njmin)
nimaxmax = max(nimaxmax, nimax)
njmaxmax = max(njmaxmax, njmax)

!$OMP parallel private(i,j,nbrs) shared(njmin,njmax,nimin,nimax,g,g0)
!$OMP do
do j = njmin, njmax
  do i = nimin, nimax

    nbrs = count(g0(max(i - 1, nimin0): min(i + 1, nimax0), &
        max(j - 1, njmin0): min(j + 1, njmax0)))

    if (nimin0 <= i .and. i <= nimax0 .and. &
        njmin0 <= j .and. j <= njmax0) then
if (g0(i, j)) then
  if (nbrs < 3) then
    g(i, j) = .false.
  else if ( nbrs < 5) then
    g(i, j) = .true.
  else
    g(i, j) = .false.
  end if
else if (nbrs == 3) then
  g(i, j) = .true.
else
  g(i, j) = .false.
end if
    else if (nbrs == 3) then
g(i, j) = .true.
    else
g(i, j) = .false.
    end if
  end do
end do
!$OMP end do
!$OMP end parallel

!deallocate(g0)
!allocate(g0(nimin: nimax, njmin: njmax))
!g0 = g

if (settings%wrt) then
  write(cn, '(i0)') n
  fres = trim(frames)//'/'//trim(filepre)//'_'//trim(cn)
  call writelifepnm(fres, g, settings)
end if

end subroutine nextgen

!=======================================================================

integer function usage()

usage = -12

write(*,*) 'Error'
write(*,*) 'Usage:'
write(*,*) tab//me//' input.json'
write(*,*)

return

end function usage

!=======================================================================

subroutine load_args(settings, io)

character :: argv*256

integer :: io, argc, i, ipos

logical :: ljson

type(life_settings) :: settings

argc = command_argument_count()
if (argc < 1) then
  io = usage()
  return
end if

ipos = 0
i = 0
do while (i < argc)
  i = i + 1
  call get_command_argument(i, argv)

  ! Positional arguments
  if (ipos == 0) then
    ipos = ipos + 1
    settings%fjson = trim(argv)
  else
    write(*,*) 'Warning:  unknown cmd argument '//trim(argv)
    write(*,*)
  end if

end do

end subroutine load_args

!=======================================================================

subroutine load_json(settings, io)

use json_module

character(len = :), allocatable :: str

integer :: io, i

logical :: found, bool

type(json_file) :: json

type(life_settings) :: settings

io = -13
write(*,*) 'Loading json file "'//settings%fjson//'" ...'

! Set defaults
settings%fseed = settings%fjson
i = scan(settings%fjson, '.', .true.)
if (i /= 0) then
  settings%fseed = settings%fjson(1: i)//'rle'
else
  settings%fseed = settings%fjson//'.rle'
end if

settings%n = 100
settings%pscale = 1

settings%xmin = -319
settings%xmax =  320
settings%ymin = -179
settings%ymax =  180

settings%wrt    = .true.
settings%trans  = .false.
settings%invert = .false.

call json%initialize()

call json%load(filename = settings%fjson)
if (json%failed()) then
  write(*,*) 'Error'
  write(*,*) 'Could not load file '//trim(settings%fjson)
  write(*,*)
  return
end if

call json%print()

call json%get('Seed file', str, found)
if (found) settings%fseed = str

call json%get('Frames', i, found)
if (found) settings%n = i

call json%get('Scale', i, found)
if (found) settings%pscale = i

call json%get('Bounds[1]', i, found)
if (found) settings%xmin = i
call json%get('Bounds[2]', i, found)
if (found) settings%ymin = i
call json%get('Bounds[3]', i, found)
if (found) settings%xmax = i
call json%get('Bounds[4]', i, found)
if (found) settings%ymax = i

call json%get('Write', bool, found)
if (found) settings%wrt = bool

call json%get('Transpose', bool, found)
if (found) settings%trans = bool

call json%get('Invert', bool, found)
if (found) settings%invert = bool

call json%destroy()

io = IO_SUCCESS

end subroutine load_json

!=======================================================================

subroutine live(settings, io)

! Live, live is a verb
!
! Live is a doing word
!
! Fearless on my breath
!
! Most faithful mirror

character :: cn*256, ans, filepre*256, ext*32, &
       fres*256, frames*256

integer :: i, j, n, niminmin, nimaxmax, njminmin, njmaxmax, &
           ifile, io

logical :: dead, fexist
logical*1, allocatable :: g(:,:), g0(:,:)

type(life_settings) :: settings

! TODO:  resolve path to fseed (and "frames") relative to fjson
inquire(file = settings%fseed, exist = fexist)
if (.not. fexist) then
  write(*,*)
  write(*,*) 'Error'
  write(*,*) 'Could not find file '//trim(settings%fseed)
  write(*,*)
  call exit(ERR_404)
end if

j = len_trim(settings%fseed)
do while (settings%fseed(j: j) /= '.')
  j = j - 1
end do
filepre = settings%fseed(1: j - 1)
ext = settings%fseed(j + 1: len_trim(settings%fseed))

if (ext == 'rle') then
  g = readrle(settings%fseed)
else if (ext== 'txt') then
  g = readtxt(settings%fseed)
else if (ext == 'cells') then
  g = readcells(settings%fseed)
else
  write(*,*)
  write(*,*) 'Error'
  write(*,*) 'Unrecognized file format '//trim(settings%fseed)
  write(*,*)
  call exit(ERR_BAD_SEED)
end if

if (settings%wrt) then

  if (     settings%xmin >= settings%xmax &
      .or. settings%ymin >= settings%ymax) then
    write(*,*)
    write(*,*) 'Error'
    write(*,*) 'Bounding box must have positive area'
    write(*,*)
    call exit(ERR_POSITIVE_BOX)
  end if

  frames = 'frames'
  inquire(file = trim(frames), exist = fexist)
  if (.not. fexist) call system('mkdir '//trim(frames))

  write(cn, '(i0)') 0
  fres = trim(frames)//'/'//trim(filepre)//'_'//trim(cn)

  inquire(file = fres, exist = fexist)
  if (fexist) then
    ! TODO:  native Windows
    call system('rm '//trim(frames)//'/'//trim(filepre)//'_*')
  end if

  call writelifepnm(fres, g, settings)

end if

niminmin = lbound(g, 1)
njminmin = lbound(g, 2)
nimaxmax = ubound(g, 1)
njmaxmax = ubound(g, 2)

allocate(g0(niminmin: nimaxmax, njminmin: njmaxmax))
g0 = g

!!  Convert input to rle for convenience
!call writerle(trim(filepre)//'_rle.rle', g)

! Time loop
dead = .false.
n = 0
do while (n < settings%n .and. .not. dead)

  ! Switch roles of g and g0 every other frame

  n = n + 1
  if (settings%wrt) write(*,*) 'Frame ', n
  call nextgen(filepre, settings, dead, g0, g, n, &
      niminmin, njminmin, nimaxmax, njmaxmax, frames)

  n = n + 1
  if (settings%wrt) write(*,*) 'Frame ', n
  call nextgen(filepre, settings, dead, g, g0, n, &
      niminmin, njminmin, nimaxmax, njmaxmax, frames)

end do

write(*,*)
write(*,*) 'number of generations = ', n
write(*,*)
write(*,*) 'lower bounds = ', niminmin, njminmin
write(*,*) 'upper bounds = ', nimaxmax, njmaxmax
write(*,*)

end subroutine live

!=======================================================================

end module lifemod

!=======================================================================

program life

use lifemod

implicit none

integer :: io

type(life_settings) :: settings

io = IO_SUCCESS

call load_args(settings, io)
if (io /= IO_SUCCESS) call exit(io)

call load_json(settings, io)
if (io /= IO_SUCCESS) call exit(io)

call live(settings, io)

call exit(io)

end program life

!=======================================================================

