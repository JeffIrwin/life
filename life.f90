! TODO:
!
!   - use logic such that if a point and its neighbors do not
!     change, don't check it in next frame
!
!   - parallelism does not seem to help for small grids

module lifemod

use pnmio

implicit none

character, parameter :: nullc = char(0), tab = char(9)
character(len = *), parameter :: me = "life", framedir = 'frames'

integer, parameter :: &
		ERR_POSITIVE_BOX = 400, &
		ERR_BAD_SEED     = 401, &
		ERR_WRITEFRAME   = 402, &
		ERR_TXT_CHARS    = 403, &
		ERR_404          = 404, &
		ERR_CELLS_CHARS  = 405, &
		ERR_CELLS_COLS   = 406, &
		ERR_RLE_READ1    = 407, &
		ERR_RLE_READ2    = 408, &
		ERR_CMD_ARGS     = 409, &
		ERR_COLORMAP     = 410, &
		IO_SUCCESS       = 0

integer, parameter :: nrgb = 3

! From colormapper_wrapper.cpp
integer, external :: load_colormap, writepng

type life_settings

	character(len = :), allocatable :: fjson, fseed, fcolormap, colormap

	integer :: n, xmin, xmax, ymin, ymax, pscale

	logical :: wrt, trans, invert, trace, ascii, png

end type life_settings

type life_data

	! TODO:  encapsulate more into this

	character(len = :), allocatable :: filepre

	integer :: frame

end type life_data

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

logical function gt(g, tran, i, j)

! helper function to avoid out-of-bounds index with short-circuit logic

logical :: tran
logical*1, allocatable :: g(:,:)

integer :: i, j

if (tran) then
	gt = g(j,i)
else
	gt = g(i,j)
end if

end function gt

!=======================================================================

subroutine writelifeframe(filename, g, s, d)

! filename      name of the file to be written to
!
! g             logical grid of live/dead cells

! Could also add fliplr and flipud options.

character :: filename*(*), c1, c0, rgb(3)
character, allocatable :: b(:,:)

double precision :: dage

integer :: i, j, il, iu, jl, ju, n1, n2, n3, n4, n13, n24, frm, &
		io, i0, i1, ii, jj, j8, ig, jg, ilo, ihi, jlo, jhi, ps, ia, ja, &
		ib, jb, maxage
integer, allocatable, save :: age(:,:)

logical :: tran
logical*1, allocatable :: g(:,:)

type(life_settings) :: s

type(life_data) :: d

n1 = s%xmin
n2 = s%ymin
n3 = s%xmax
n4 = s%ymax
ps = s%pscale

tran = s%trans

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

if (s%trace) then

	if (s%ascii) then
		frm = PNM_RGB_ASCII
	else
		frm = PNM_RGB_BINARY
	end if

	allocate(b((n4 - n2 + 1) * nrgb * ps, (n3 - n1 + 1) * ps))

	if (.not. allocated(age)) then

		! Number of frames since a grid unit was last alive.  So actually not
		! "age" unless you invert the usual boolean interpretation of life and
		! death.
		allocate(age(n4 - n2 + 1, n3 - n1 + 1))

		! Points that were never alive can be inferred from having an age
		! greater than the current number of frames.
		age = 2

	end if

else

	if (s%ascii) then

		frm = PNM_BW_ASCII
		allocate(b((n4 - n2 + 1) * ps, (n3 - n1 + 1) * ps))

	else

		! Binary:  pack 8 B&W pixel bits into a 1 byte character.
		! Only the horizontal dimension is padded.
		frm = PNM_BW_BINARY
		allocate(b(ceiling((n4 - n2 + 1) / 8.d0) * ps, (n3 - n1 + 1) * ps))

	end if

end if

ilo = max(n1, il)
ihi = min(n3, iu)
jlo = max(n2, jl)
jhi = min(n4, ju)

if (s%trace) then

	! RGB

	if (s%invert) then
		b = char(0)
	else
		b = char(int(z'ff'))
	end if

	age = age + 1

	do i = ilo, ihi
		ia = n3 - i + 1
		do j = jlo, jhi
			ja = j - n2 + 1
			if (gt(g, tran, i, j)) age(ja, ia) = 0
		end do
	end do

	! Arbitrary, could be something else.  Don't want to use the actual oldest
	! pixel in the grid, as that could be quite old and dilute the rest of the
	! color range.
	maxage = 255

	! Bounds of g may shrink, but we need to go outside those bounds to map
	! ages.
	do i = n1, n3
		ia = n3 - i + 1
		ib = ia * ps
		do j = n2, n4
			ja = j - n2 + 1
			jb = ja * nrgb * ps

			! Use 0 for dead pixels, otherwise colormapper uses NaN color for
			! values outside of range [0, 1].
			if (age(ja, ia) > min(maxage, d%frame)) then
				dage = 0.d0
			else
				! Linear decay
				dage = dble(maxage - age(ja, ia)) / maxage
			end if

			! From colormapper_wrapper.cpp
			call map(dage, rgb)

			b(jb - nrgb * ps + 1: jb: nrgb, ib - ps + 1: ib) = rgb(1)
			b(jb - nrgb * ps + 2: jb: nrgb, ib - ps + 1: ib) = rgb(2)
			b(jb - nrgb * ps + 3: jb: nrgb, ib - ps + 1: ib) = rgb(3)

		end do
	end do

else

	! Black and white

	if (s%invert) then
		i0 = 1
		i1 = 0
		if (.not. s%ascii) b = char(0)      ! 00000000
	else
		i0 = 0
		i1 = 1
		if (.not. s%ascii) b = char(int(z'ff'))  ! 11111111
	end if
	c0 = char(i0)
	c1 = char(i1)

	if (s%ascii) b = c1

	! Array b is scaled by the pixel scaling factor s%pscale,
	! but array g is not.  Loop the b indices i and j faster than the
	! g indices ig and jg.

	ig = ilo - 1
	do i = ilo * ps, ihi * ps
		if (mod(i, ps) == 0) ig = ig + 1
		ii = n3 * ps - i + 1

		jg = jlo - 1
		do j = jlo * ps, jhi * ps
			if (mod(j, ps) == 0) jg = jg + 1

			if (gt(g, tran, ig, jg)) then
				j8 = j - n2 * ps + 1

				if (s%ascii) then
					b(j8, ii) = c0
				else

					! j8 is the bitwise index and jj is the bytewise index.
					! Use mod(j8,8) to get the endian-flipped index of the bit
					! within the byte to be set or cleared.  ichar(.,1) casts
					! a character to a 1-byte int, and char casts the int
					! back to a character.

					jj = j8 / 8

					if (s%invert) then
						b(jj,ii) = char(ibset(ichar(b(jj,ii), 1), 7 - mod(j8,8)))
					else
						b(jj,ii) = char(ibclr(ichar(b(jj,ii), 1), 7 - mod(j8,8)))
					end if

				end if
			end if
		end do
	end do
end if

if (s%trace .and. s%png) then

	io = writepng(b, (n4 - n2 + 1) * ps, (n3 - n1 + 1) * ps, &
		trim(filename)//'.png'//nullc)
	if (io /= 0) call exit(ERR_WRITEFRAME)

else

	io = writepnm(frm, b, filename, .false.)
	if (io /= 0) call exit(ERR_WRITEFRAME)

end if

end subroutine writelifeframe

!=======================================================================

subroutine nextgen(s, dead, g0, g, d, &
		niminmin, njminmin, nimaxmax, njmaxmax)

character :: cn*256, fres*256

integer :: i, j, nimin, njmin, nimax, njmax, nimin0, &
		nimax0, njmin0, njmax0, nbrs, niminmin, nimaxmax, &
		njminmin, njmaxmax

logical, intent(inout) :: dead
logical*1, allocatable :: g(:,:), g0(:,:)

type(life_settings) :: s
type(life_data) :: d

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

if (s%wrt) then
	write(cn, '(i0)') d%frame
	fres = framedir//'/'//trim(d%filepre)//'_'//trim(cn)
	call writelifeframe(fres, g, s, d)
end if

end subroutine nextgen

!=======================================================================

integer function usage()

usage = ERR_CMD_ARGS

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
settings%trace  = .false.
settings%ascii  = .false.
settings%png    = .false.  ! default pnm

settings%fcolormap = ""
settings%colormap  = ""

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

call json%get('Colormap file', str, found)
if (found) settings%fcolormap = str

call json%get('Colormap name', str, found)
if (found) settings%colormap = str

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

call json%get('PNG', bool, found)
if (found) settings%png = bool

call json%get('Transpose', bool, found)
if (found) settings%trans = bool

call json%get('Invert', bool, found)
if (found) settings%invert = bool

call json%get('Trace', bool, found)
if (found) settings%trace = bool

call json%get('ASCII', bool, found)
if (found) settings%ascii = bool

call json%destroy()

io = IO_SUCCESS

end subroutine load_json

!=======================================================================

subroutine stitch(s, d)

character(len = :), allocatable :: ffmpeg, ext

type(life_settings) :: s

type(life_data) :: d

write(*,*) 'Running ffmpeg ...'

if (s%trace) then
	if (s%png) then
		ext = 'png'
	else
		ext = 'ppm'
	end if
else
	ext = 'pbm'
end if

ffmpeg = 'ffmpeg -i '//framedir//'/'//d%filepre//'_%d.'//ext//' -c:v libx264' &
	//' -pix_fmt yuv420p '//d%filepre//'.mp4 -y'

write(*,*) 'Command = "', ffmpeg, '"'

call system(ffmpeg)

write(*,*)

end subroutine stitch

!=======================================================================

subroutine live(s, io)

! Live, live is a verb
!
! Live is a doing word
!
! Fearless on my breath
!
! Most faithful mirror

character :: cn*256, ext*32, fres*256

integer :: j, niminmin, nimaxmax, njminmin, njmaxmax, io

logical :: dead, fexist
logical*1, allocatable :: g(:,:), g0(:,:)

type(life_settings) :: s

type(life_data) :: d

! TODO:  resolve path to fseed (and "frames") relative to fjson
inquire(file = s%fseed, exist = fexist)
if (.not. fexist) then
	write(*,*)
	write(*,*) 'Error'
	write(*,*) 'Could not find file '//trim(s%fseed)
	write(*,*)
	call exit(ERR_404)
end if

j = len_trim(s%fjson)
do while (s%fjson(j: j) /= '.')
	j = j - 1
end do
d%filepre = s%fjson(1: j - 1)

j = len_trim(s%fseed)
do while (s%fseed(j: j) /= '.')
	j = j - 1
end do
ext = s%fseed(j + 1: len_trim(s%fseed))

if (ext == 'rle') then
	g = readrle(s%fseed)
else if (ext== 'txt') then
	g = readtxt(s%fseed)
else if (ext == 'cells') then
	g = readcells(s%fseed)
else
	write(*,*)
	write(*,*) 'Error'
	write(*,*) 'Unrecognized file format '//trim(s%fseed)
	write(*,*)
	call exit(ERR_BAD_SEED)
end if

dead = .false.
d%frame = 0

io = load_colormap(s%fcolormap//nullc, s%colormap//nullc)
if (io /= 0) call exit(ERR_COLORMAP)

if (s%wrt) then

	if (s%xmin >= s%xmax .or. s%ymin >= s%ymax) then
		write(*,*)
		write(*,*) 'Error'
		write(*,*) 'Bounding box must have positive area'
		write(*,*)
		call exit(ERR_POSITIVE_BOX)
	end if

	inquire(file = framedir, exist = fexist)
	if (.not. fexist) call system('mkdir '//framedir)

	write(cn, '(i0)') 0
	fres = framedir//'/'//trim(d%filepre)//'_'//trim(cn)

	inquire(file = fres, exist = fexist)
	if (fexist) then
		! TODO:  native Windows
		call system('rm '//framedir//'/'//trim(d%filepre)//'_*')
	end if

	call writelifeframe(fres, g, s, d)

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
do while (d%frame < s%n .and. .not. dead)

	! Switch roles of g and g0 every other frame

	d%frame = d%frame + 1
	if (.not. s%wrt) write(*,*) 'Frame ', d%frame
	call nextgen(s, dead, g0, g, d, niminmin, njminmin, nimaxmax, njmaxmax)

	d%frame = d%frame + 1
	if (.not. s%wrt) write(*,*) 'Frame ', d%frame
	call nextgen(s, dead, g, g0, d, niminmin, njminmin, nimaxmax, njmaxmax)

end do

write(*,*)
write(*,*) 'Number of generations = ', d%frame
write(*,*)
write(*,*) 'Lower bounds = ', niminmin, njminmin
write(*,*) 'Upper bounds = ', nimaxmax, njmaxmax
write(*,*)

call stitch(s, d)

write(*,*) 'End of life!'
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

